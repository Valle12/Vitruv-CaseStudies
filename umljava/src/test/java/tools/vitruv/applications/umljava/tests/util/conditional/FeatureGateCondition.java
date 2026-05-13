package tools.vitruv.applications.umljava.tests.util.conditional;

import java.lang.reflect.AnnotatedElement;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import org.jspecify.annotations.NullMarked;
import org.junit.jupiter.api.extension.ConditionEvaluationResult;
import org.junit.jupiter.api.extension.ExecutionCondition;
import org.junit.jupiter.api.extension.ExtensionContext;

@NullMarked
public class FeatureGateCondition implements ExecutionCondition {

  @Override
  public ConditionEvaluationResult evaluateExecutionCondition(ExtensionContext context) {
    Optional<Method> testMethodOpt = context.getTestMethod();
    Class<?> testClass = context.getTestClass().orElse(null);

    // Class-level evaluation (used when context is a container/class).
    if (testMethodOpt.isEmpty()) {
      if (testClass == null) {
        return ConditionEvaluationResult.enabled("no test class context");
      }

      return evaluate(collectAnnotationsFromClassHierarchy(testClass));
    }

    // Method-level evaluation: collect from method + its declaring class hierarchy.
    Method method = testMethodOpt.get();
    List<RequiresFeatures> requires = new ArrayList<>();
    List<IncompatibleFeatures> incompatible = new ArrayList<>();
    collectAnnotations(method, requires, incompatible);
    if (testClass != null) {
      collectFromClassHierarchy(testClass, requires, incompatible);
    }

    return evaluate(requires, incompatible);
  }

  private List<List<?>> collectAnnotationsFromClassHierarchy(Class<?> clazz) {
    List<RequiresFeatures> requires = new ArrayList<>();
    List<IncompatibleFeatures> incompatible = new ArrayList<>();
    collectFromClassHierarchy(clazz, requires, incompatible);
    return List.of(requires, incompatible);
  }

  private ConditionEvaluationResult evaluate(List<List<?>> bundle) {
    // TODO proper checking
    @SuppressWarnings("unchecked")
    List<RequiresFeatures> requires = (List<RequiresFeatures>) bundle.get(0);
    @SuppressWarnings("unchecked")
    List<IncompatibleFeatures> incompatible = (List<IncompatibleFeatures>) bundle.get(1);
    return evaluate(requires, incompatible);
  }

  private ConditionEvaluationResult evaluate(
      List<RequiresFeatures> requires, List<IncompatibleFeatures> incompatible) {
    for (RequiresFeatures req : requires) {
      for (String feature : req.value()) {
        if (!ActiveFeatures.isActive(feature)) {
          return ConditionEvaluationResult.disabled(
              "required feature '" + feature + "' is not active in this config");
        }
      }
    }

    for (IncompatibleFeatures inc : incompatible) {
      for (String feature : inc.value()) {
        if (ActiveFeatures.isActive(feature)) {
          return ConditionEvaluationResult.disabled(
              "incompatible feature '" + feature + "' is active in this config");
        }
      }
    }

    return ConditionEvaluationResult.enabled("feature gate satisfied");
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
}
