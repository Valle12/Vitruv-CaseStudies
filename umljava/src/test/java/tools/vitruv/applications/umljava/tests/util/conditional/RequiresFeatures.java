package tools.vitruv.applications.umljava.tests.util.conditional;

import java.lang.annotation.ElementType;
import java.lang.annotation.Repeatable;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
@Repeatable(RequiresFeatures.Container.class)
public @interface RequiresFeatures {
  String[] value();

  @Retention(RetentionPolicy.RUNTIME)
  @Target({ElementType.METHOD, ElementType.TYPE})
  @interface Container {
    RequiresFeatures[] value();
  }
}
