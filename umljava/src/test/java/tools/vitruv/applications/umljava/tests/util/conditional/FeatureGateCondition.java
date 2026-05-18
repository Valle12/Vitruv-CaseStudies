package tools.vitruv.applications.umljava.tests.util.conditional;

import java.lang.reflect.AnnotatedElement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.jspecify.annotations.NullMarked;
import org.junit.jupiter.api.extension.AfterEachCallback;
import org.junit.jupiter.api.extension.ExtensionContext;
import org.junit.jupiter.api.extension.ExtensionContext.Namespace;
import org.junit.jupiter.api.extension.ExtensionContext.Store;
import org.junit.jupiter.api.extension.LifecycleMethodExecutionExceptionHandler;
import org.junit.jupiter.api.extension.TestExecutionExceptionHandler;
import org.opentest4j.AssertionFailedError;

/**
 * Inverts test outcomes when an annotated feature gate is not satisfied: any failure in
 * {@code @BeforeEach}, the test body, or {@code @AfterEach} is treated as the expected outcome, and
 * a clean pass is reported as a failure ("expected to fail, but didn't").
 */
@NullMarked
public class FeatureGateCondition
    implements TestExecutionExceptionHandler,
        LifecycleMethodExecutionExceptionHandler,
        AfterEachCallback {

  private static final Namespace NAMESPACE = Namespace.create(FeatureGateCondition.class);
  private static final String OBSERVED_FAILURE_KEY = "observedExpectedFailure";

  @Override
  public void handleTestExecutionException(ExtensionContext context, Throwable throwable)
      throws Throwable {
    swallowOrRethrow(context, throwable);
  }

  @Override
  public void handleBeforeEachMethodExecutionException(
      ExtensionContext context, Throwable throwable) throws Throwable {
    swallowOrRethrow(context, throwable);
  }

  @Override
  public void handleAfterEachMethodExecutionException(ExtensionContext context, Throwable throwable)
      throws Throwable {
    swallowOrRethrow(context, throwable);
  }

  @Override
  public void afterEach(ExtensionContext context) {
    GateOutcome outcome = evaluateGate(context);
    if (outcome.satisfied) {
      return;
    }

    Store store = context.getStore(NAMESPACE);
    if (Boolean.TRUE.equals(store.get(OBSERVED_FAILURE_KEY, Boolean.class))) {
      return;
    }

    throw new AssertionFailedError(
        "Test was expected to fail because "
            + outcome.reason
            + ", but it completed without any failure.");
  }

  private void swallowOrRethrow(ExtensionContext context, Throwable throwable) throws Throwable {
    GateOutcome outcome = evaluateGate(context);
    if (outcome.satisfied) {
      throw throwable;
    }

    context.getStore(NAMESPACE).put(OBSERVED_FAILURE_KEY, Boolean.TRUE);
  }

  private GateOutcome evaluateGate(ExtensionContext context) {
    List<RequiresFeatures> methodRequires = new ArrayList<>();
    List<RequiresFeatures> classRequires = new ArrayList<>();
    List<IncompatibleFeatures> incompatible = new ArrayList<>();
    context.getTestMethod().ifPresent(m -> collectAnnotations(m, methodRequires, incompatible));
    context
        .getTestClass()
        .ifPresent(c -> collectFromClassHierarchy(c, classRequires, incompatible));
    return evaluate(classRequires, methodRequires, incompatible);
  }

  private GateOutcome evaluate(
      List<RequiresFeatures> classRequires,
      List<RequiresFeatures> methodRequires,
      List<IncompatibleFeatures> incompatible) {
    for (RequiresFeatures req : classRequires) {
      if (!allActive(req.value())) {
        return GateOutcome.unsatisfied(
            "class-level required-features combination ["
                + String.join(", ", req.value())
                + "] is not fully active in this config");
      }
    }

    if (!methodRequires.isEmpty()) {
      boolean anyCombinationActive = false;
      List<String> tried = new ArrayList<>(methodRequires.size());
      for (RequiresFeatures req : methodRequires) {
        if (allActive(req.value())) {
          anyCombinationActive = true;
          break;
        }

        tried.add("[" + String.join(", ", req.value()) + "]");
      }

      if (!anyCombinationActive) {
        return GateOutcome.unsatisfied(
            "no method-level required-features combination is fully active in this config "
                + "(checked "
                + String.join(" | ", tried)
                + ")");
      }
    }

    for (IncompatibleFeatures inc : incompatible) {
      if (allActive(inc.value())) {
        return GateOutcome.unsatisfied(
            "incompatible-features combination ["
                + String.join(", ", inc.value())
                + "] is fully active in this config");
      }
    }

    return GateOutcome.satisfied();
  }

  private static boolean allActive(String[] features) {
    for (String feature : features) {
      if (!ActiveFeatures.isActive(feature)) {
        return false;
      }
    }

    return true;
  }

  private void collectFromClassHierarchy(
      Class<?> clazz, List<RequiresFeatures> requires, List<IncompatibleFeatures> incompatible) {
    Class<?> c = clazz;
    while (c != null && c != Object.class) {
      collectAnnotations(c, requires, incompatible);
      c = c.getSuperclass();
    }
  }

  private void collectAnnotations(
      AnnotatedElement element,
      List<RequiresFeatures> requires,
      List<IncompatibleFeatures> incompatible) {
    RequiresFeatures direct = element.getAnnotation(RequiresFeatures.class);
    if (direct != null) {
      requires.add(direct);
    }

    RequiresFeatures.Container reqContainer =
        element.getAnnotation(RequiresFeatures.Container.class);
    if (reqContainer != null) {
      requires.addAll(Arrays.asList(reqContainer.value()));
    }

    IncompatibleFeatures directInc = element.getAnnotation(IncompatibleFeatures.class);
    if (directInc != null) {
      incompatible.add(directInc);
    }

    IncompatibleFeatures.Container incContainer =
        element.getAnnotation(IncompatibleFeatures.Container.class);
    if (incContainer != null) {
      incompatible.addAll(Arrays.asList(incContainer.value()));
    }
  }

  private static final class GateOutcome {
    final boolean satisfied;
    final String reason;

    private GateOutcome(boolean satisfied, String reason) {
      this.satisfied = satisfied;
      this.reason = reason;
    }

    static GateOutcome satisfied() {
      return new GateOutcome(true, "feature gate satisfied");
    }

    static GateOutcome unsatisfied(String reason) {
      return new GateOutcome(false, reason);
    }
  }
}
