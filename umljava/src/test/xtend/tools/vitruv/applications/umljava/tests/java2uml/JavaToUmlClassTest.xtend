package tools.vitruv.applications.umljava.tests.java2uml

import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.uml2.uml.VisibilityKind
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.EnumSource
import tools.vitruv.applications.util.temporary.java.JavaVisibility

import static org.hamcrest.CoreMatchers.*
import static org.hamcrest.MatcherAssert.assertThat
import static org.junit.jupiter.api.Assertions.assertEquals
import static org.junit.jupiter.api.Assertions.assertFalse
import static org.junit.jupiter.api.Assertions.assertTrue
import static tools.vitruv.applications.testutility.integration.UmlElementsTestAssertions.*
import static tools.vitruv.applications.util.temporary.java.JavaModificationUtil.*
import static tools.vitruv.applications.util.temporary.java.JavaModifierUtil.getUmlVisibilityKindFromJavaVisibilityConstant

import static extension tools.vitruv.applications.testutility.uml.UmlQueryUtil.*
import static extension tools.vitruv.applications.umljava.tests.util.JavaQueryUtil.*
import static extension tools.vitruv.applications.util.temporary.java.JavaContainerAndClassifierUtil.*
import static extension tools.vitruv.applications.util.temporary.java.JavaModifierUtil.*
import tools.vitruv.applications.umljava.tests.util.conditional.IncompatibleFeatures
import tools.vitruv.applications.umljava.tests.util.conditional.RequiresFeatures

/**
 * A Test class to test classes and their traits.
 */
class JavaToUmlClassTest extends AbstractJavaToUmlTest {
	static val PACKAGE_NAME = "packagename"
	static val CLASS_NAME = "ClassName"
	static val CLASS_RENAMED = "ClassRenamed"
	static val SUPER_CLASS_NAME = "SuperClassName"
	static val INTERFACE_NAME = "InterfaceName"
	static val INTERFACE_NAME2 = "InterfaceName2"

	/**
	 * Tests if a corresponding Java class is created when a UML class is created.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testCreateClass() {
		createJavaClassInRootPackage(CLASS_NAME)
		assertSingleClassWithNameInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			assertUmlClassTraits(umlClass, CLASS_NAME, VisibilityKind.PACKAGE_LITERAL, false, false, defaultUmlModel)
		]
	}

	/**
	 * Tests if a corresponding Java class is created when a UML class is created within a package.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testCreateClassInPackage() {
		createJavaPackageInRootPackage(PACKAGE_NAME)
		createJavaClassInPackage(#[PACKAGE_NAME], CLASS_NAME)
		assertSingleClassWithNameInPackage(PACKAGE_NAME, CLASS_NAME)
		assertNoClassifierWithNameInRootPackage(CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
		validateUmlView [
			val umlPackage = defaultUmlModel.claimPackage(PACKAGE_NAME)
			val umlClass = umlPackage.claimClass(CLASS_NAME)
			assertUmlClassTraits(umlClass, CLASS_NAME, VisibilityKind.PACKAGE_LITERAL, false, false, umlPackage)
		]
	}

	/**
	 * Tests if renaming a java class also renames the corresponding UML class.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testRenameClass() {
		createJavaClassInRootPackage(CLASS_NAME)
		changeJavaView [
			claimJavaClass(CLASS_NAME) => [
				changeNameWithCompilationUnit(CLASS_RENAMED)
			]
			moveJavaRootElement(claimJavaCompilationUnit(CLASS_RENAMED))
		]
		assertSingleClassWithNameInRootPackage(CLASS_RENAMED)
		assertNoClassifierWithNameInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_RENAMED)
			assertUmlClassTraits(umlClass, CLASS_RENAMED, VisibilityKind.PACKAGE_LITERAL, false, false, defaultUmlModel)
		]
	}

	/**
	 * Tests if moving a Java class leads to the movement of the corresponding UML class.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testMoveClass() {
		createJavaPackageInRootPackage(PACKAGE_NAME)
		createJavaClassInRootPackage(CLASS_NAME)
		changeJavaView [
			moveJavaRootElement(claimJavaCompilationUnit(CLASS_NAME) => [
				namespaces += PACKAGE_NAME
				updateCompilationUnitName(CLASS_NAME)
			])
		]
		assertSingleClassWithNameInPackage(PACKAGE_NAME, CLASS_NAME)
		assertNoClassifierWithNameInRootPackage(CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
		changeJavaView [
			moveJavaRootElement(claimJavaCompilationUnit(PACKAGE_NAME + "." + CLASS_NAME) => [
				namespaces.clear
				updateCompilationUnitName(CLASS_NAME)
			])
		]
		assertSingleClassWithNameInRootPackage(CLASS_NAME)
		assertNoClassifierWithNameInPackage(PACKAGE_NAME, CLASS_NAME)
	}

	/**
	 * Tests if deleting a Java class also cause the deleting of the corresponding
	 * UML class.
	 */
	@Test
	def void testDeleteClass() {
		createJavaClassInRootPackage(CLASS_NAME)
		changeJavaView [
			EcoreUtil.delete(claimJavaClass(CLASS_NAME))
		]
		assertNoClassifierWithNameInRootPackage(CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
	}

	/**
	 * Tests if deleting a Java compilation unit also cause the deleting of the corresponding
	 * UML class.
	 */
	@Test
	def void testDeleteCompilationUnit() {
		createJavaClassInRootPackage(CLASS_NAME)
		changeJavaView [
			EcoreUtil.delete(claimJavaCompilationUnit(CLASS_NAME))
		]
		assertNoClassifierWithNameInRootPackage(CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
	}

	private def void changeAndCheckPropertyOfClass(String className,
		(org.emftext.language.java.classifiers.Class)=>void changeJavaClass,
		(org.eclipse.uml2.uml.Class)=>void validateUmlClass) {
		changeJavaView [
			claimJavaClass(className) => [
				changeJavaClass.apply(it)
			]
		]
		assertSingleClassWithNameInRootPackage(className)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(className)
			validateUmlClass.apply(umlClass)
		]
	}

	/**
	 * Checks if visibility changes are propagated to the UML class.
	 */
	@ParameterizedTest
	@EnumSource(value=JavaVisibility, names=#["PACKAGE"], mode=EnumSource.Mode.EXCLUDE)
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeClassVisibility(JavaVisibility visibility) {
		createJavaClassInRootPackage(CLASS_NAME)
		changeAndCheckPropertyOfClass(CLASS_NAME, [javaVisibilityModifier = visibility], [
			assertUmlNamedElementHasVisibility(it, getUmlVisibilityKindFromJavaVisibilityConstant(visibility))
		])
		changeAndCheckPropertyOfClass(CLASS_NAME, [javaVisibilityModifier = JavaVisibility.PACKAGE], [
			assertUmlNamedElementHasVisibility(it,
				getUmlVisibilityKindFromJavaVisibilityConstant(JavaVisibility.PACKAGE))
		])
	}

	/**
	 * Tests the change of the abstract value in UML.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeAbstractClass() {
		createJavaClassInRootPackage(CLASS_NAME)
		changeAndCheckPropertyOfClass(CLASS_NAME, [abstract = true], [
			assertThat("UML class must be abstract", it.abstract, is(true))
		])
		changeAndCheckPropertyOfClass(CLASS_NAME, [abstract = false], [
			assertThat("UML class must not be abstract", it.abstract, is(false))
		])
	}

	/**
	 * Checks if the changing the final value in the Java class
	 * causes the correct change in the Uml class.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeFinalClass() {
		createJavaClassInRootPackage(CLASS_NAME)
		changeAndCheckPropertyOfClass(CLASS_NAME, [final = true], [
			assertThat("UML class must be final", it.finalSpecialization, is(true))
		])
		changeAndCheckPropertyOfClass(CLASS_NAME, [final = false], [
			assertThat("UML class must not be final", it.finalSpecialization, is(false))
		])
	}

	/**
	 * Tests if add a super class is correctly reflected on the UML side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testSuperClassChanged() {
		createJavaClassInRootPackage(CLASS_NAME)
		createJavaClassInRootPackage(SUPER_CLASS_NAME)
		changeJavaView [
			val superClass = claimJavaClass(SUPER_CLASS_NAME)
			claimJavaClass(CLASS_NAME) => [
				extends = createNamespaceClassifierReference(superClass)
			]
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		assertClassWithNameInRootPackage(SUPER_CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			val umlSuperClass = defaultUmlModel.claimClass(SUPER_CLASS_NAME)
			assertUmlClassifierHasSuperClassifier(umlClass, umlSuperClass)
		]
	}

	/**
	 * Tests if removing a super class is reflected on the UML side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testRemoveSuperClass() {
		createJavaClassInRootPackage(CLASS_NAME)
		createJavaClassInRootPackage(SUPER_CLASS_NAME)
		changeJavaView [
			val superClass = claimJavaClass(SUPER_CLASS_NAME)
			claimJavaClass(CLASS_NAME) => [
				extends = createNamespaceClassifierReference(superClass)
			]
		]
		changeJavaView [
			claimJavaClass(CLASS_NAME) => [
				EcoreUtil.delete(extends)
			]
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			val umlSuperClass = defaultUmlModel.claimClass(SUPER_CLASS_NAME)
			assertUmlClassifierDontHaveSuperClassifier(umlClass, umlSuperClass)
		]
	}

	/**
	 * Check the creation of an interface implementation on the UML side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	@IncompatibleFeatures("RealizationSuffix")
	def void testAddClassImplement() {
		createJavaClassInRootPackage(CLASS_NAME)
		createJavaInterfaceInRootPackage(INTERFACE_NAME)
		changeJavaView [
			val javaInterface = claimJavaInterface(INTERFACE_NAME)
			claimJavaClass(CLASS_NAME) => [
				implements += createNamespaceClassifierReference(javaInterface)
			]
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			val umlInterface = defaultUmlModel.claimInterface(INTERFACE_NAME)
			assertUmlClassHasImplement(umlClass, umlInterface)
		]
	}

	/**
	 * Tests if removing an implementation relation is correctly reflected on the UML side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	@IncompatibleFeatures("RealizationSuffix")
	def void testRemoveClassImplement() {
		createJavaClassInRootPackage(CLASS_NAME)
		createJavaInterfaceInRootPackage(INTERFACE_NAME)
		createJavaInterfaceInRootPackage(INTERFACE_NAME2)
		changeJavaView [
			val firstJavaInterface = claimJavaInterface(INTERFACE_NAME)
			val secondJavaInterface = claimJavaInterface(INTERFACE_NAME2)
			claimJavaClass(CLASS_NAME) => [
				implements += createNamespaceClassifierReference(firstJavaInterface)
				implements += createNamespaceClassifierReference(secondJavaInterface)
			]
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			val umlFirstInterface = defaultUmlModel.claimInterface(INTERFACE_NAME)
			val umlSecondInterface = defaultUmlModel.claimInterface(INTERFACE_NAME2)
			assertUmlClassHasImplement(umlClass, umlFirstInterface)
			assertUmlClassHasImplement(umlClass, umlSecondInterface)
		]
		changeJavaView [
			claimJavaClass(CLASS_NAME) => [
				implements.remove(0)
			]
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			val umlFirstInterface = defaultUmlModel.claimInterface(INTERFACE_NAME)
			val umlSecondInterface = defaultUmlModel.claimInterface(INTERFACE_NAME2)
			assertUmlClassDontHaveImplement(umlClass, umlFirstInterface)
			assertUmlClassHasImplement(umlClass, umlSecondInterface)
		]
	}

	@Test
	@RequiresFeatures(#["ClassCreation.Class", "RealizationSuffix"])
	def void testRealizationSuffixAppendedOnImplements() {
		createJavaClassInRootPackage(CLASS_NAME)
		createJavaInterfaceInRootPackage(INTERFACE_NAME)
		changeJavaView [
			val javaInterface = claimJavaInterface(INTERFACE_NAME)
			claimJavaClass(CLASS_NAME) => [
				implements += createNamespaceClassifierReference(javaInterface)
			]
		]
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME + "Impl")
			assertEquals(CLASS_NAME + "Impl", umlClass.name)
		]
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME + "Impl")
			assertEquals(CLASS_NAME + "Impl", javaClass.name)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Interface")
	def void testJavaClassBecomesUmlInterface() {
		createJavaClassInRootPackage(CLASS_NAME)
		validateUmlView [
			assertTrue(defaultUmlModel.packagedElements.exists [
				it instanceof org.eclipse.uml2.uml.Interface && (it as org.eclipse.uml2.uml.Interface).name == CLASS_NAME
			], "Java class must produce a UML interface when ClassCreation.Interface is active")
			assertFalse(defaultUmlModel.packagedElements.exists [
				it instanceof org.eclipse.uml2.uml.Class && (it as org.eclipse.uml2.uml.Class).name == CLASS_NAME
			], "no UML class must be produced when ClassCreation.Interface is active")
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Enum")
	def void testJavaClassBecomesUmlEnum() {
		createJavaClassInRootPackage(CLASS_NAME)
		validateUmlView [
			val umlEnum = defaultUmlModel.claimEnum(CLASS_NAME)
			assertEquals(CLASS_NAME, umlEnum.name)
			assertFalse(defaultUmlModel.packagedElements.exists [
				it instanceof org.eclipse.uml2.uml.Class && (it as org.eclipse.uml2.uml.Class).name == CLASS_NAME
			], "no UML class must be produced when ClassCreation.Enum is active")
		]
	}

	@Test
	@RequiresFeatures(#["ClassCreation.Class", "ConstructorCreation"])
	def void testJavaConstructorAddedOnClassCreation() {
		createJavaClassInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			assertFalse(javaClass.members.filter(org.emftext.language.java.members.Constructor).empty,
				"a default constructor must be added on the Java side when ConstructorCreation is active")
		]
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(CLASS_NAME)
			assertFalse(umlClass.ownedOperations.filter[name == CLASS_NAME].empty,
				"a corresponding constructor operation must be added on the UML side when ConstructorCreation is active")
		]
	}

	static class BidirectionalTest extends JavaToUmlClassTest {
		override protected enableTransitiveCyclicChangePropagation() {
			true
		}
	}

}
