package tools.vitruv.applications.umljava.tests.uml2java

import org.eclipse.uml2.uml.UMLFactory
import org.eclipse.uml2.uml.VisibilityKind
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.EnumSource

import static org.junit.jupiter.api.Assertions.assertEquals
import static org.junit.jupiter.api.Assertions.assertFalse
import static org.junit.jupiter.api.Assertions.assertNull
import static org.junit.jupiter.api.Assertions.assertTrue
import static tools.vitruv.applications.testutility.integration.JavaElementsTestAssertions.*
import static tools.vitruv.applications.util.temporary.java.JavaModifierUtil.getJavaVisibilityConstantFromUmlVisibilityKind
import static tools.vitruv.applications.util.temporary.java.JavaTypeUtil.getClassifierFromTypeReference

import static extension edu.kit.ipd.sdq.commons.util.java.lang.IterableUtil.claimOne
import static extension tools.vitruv.applications.testutility.uml.UmlQueryUtil.*
import static extension tools.vitruv.applications.umljava.tests.util.JavaQueryUtil.*
import tools.vitruv.applications.umljava.tests.util.conditional.IncompatibleFeatures
import tools.vitruv.applications.umljava.tests.util.conditional.RequiresFeatures

/**
 * This class provides tests for basic class tests in the UML to Java direction
 */
class UmlToJavaClassTest extends AbstractUmlToJavaTest {
	static val PACKAGE_NAME = "rootpackage"
	static val DEFAULT_CLASS_NAME = "TestClass"
	static val RENAMED_CLASS_NAME = "RenamedTestClass"
	static val ADDITIONAL_CLASS_NAME = "AdditionalClass"
	static val DEFAULT_INTERFACE_NAME = "TestInterface"
	static val ADDITIONAL_INTERFACE_NAME = "AdditionalInterface"

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testCreateClass() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		assertSingleClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testCreateClassInPackage() {
		createClassInPackage(PACKAGE_NAME, DEFAULT_CLASS_NAME)
		assertSingleClassWithNameInPackage(PACKAGE_NAME, DEFAULT_CLASS_NAME)
		assertNoClassifierWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testDeleteClass() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).destroy
		]
		assertNoClassifierWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
	}

	@ParameterizedTest
	@EnumSource(value=VisibilityKind, names=#["PUBLIC_LITERAL"], mode=EnumSource.Mode.EXCLUDE)
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeClassVisibility(VisibilityKind visibility) {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).visibility = visibility
		]
		assertSingleClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertJavaModifiableHasVisibility(javaClass, getJavaVisibilityConstantFromUmlVisibilityKind(visibility))
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeAbstractClass() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).isAbstract = true
		]
		assertSingleClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertJavaModifiableAbstract(javaClass, true)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testRenameClass() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).name = RENAMED_CLASS_NAME
		]
		assertSingleClassWithNameInRootPackage(RENAMED_CLASS_NAME)
		assertNoClassifierWithNameInRootPackage(DEFAULT_CLASS_NAME)
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testMoveClass() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		createPackageInRootPackage(PACKAGE_NAME)
		changeUmlModel [
			claimPackage(PACKAGE_NAME).packagedElements += claimClass(DEFAULT_CLASS_NAME)
		]
		assertSingleClassWithNameInPackage(PACKAGE_NAME, DEFAULT_CLASS_NAME)
		assertNoClassifierWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
		changeUmlModel [
			packagedElements += claimPackage(PACKAGE_NAME).claimClass(DEFAULT_CLASS_NAME)
		]
		assertSingleClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertNoClassifierWithNameInPackage(PACKAGE_NAME, DEFAULT_CLASS_NAME)
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeFinalClass() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).isFinalSpecialization = true
		]
		assertSingleClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertJavaModifiableFinal(javaClass, true)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testSuperClassChanged() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			val existingClass = claimClass(DEFAULT_CLASS_NAME)
			val superClass = UMLFactory.eINSTANCE.createClass
			packagedElements += superClass => [
				name = ADDITIONAL_CLASS_NAME
			]
			existingClass => [
				generals += superClass
			]
		]
		assertClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertClassWithNameInRootPackage(ADDITIONAL_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			val javaSuperClass = claimJavaClass(ADDITIONAL_CLASS_NAME)
			assertHasSuperClass(javaClass, javaSuperClass)
		]
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME) => [
				generals.clear
			]
		]
		assertClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertClassWithNameInRootPackage(ADDITIONAL_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertNull(javaClass.extends)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	@IncompatibleFeatures("RealizationSuffix")
	@IncompatibleFeatures("InterfacePrefix")
	def void testAddClassImplements() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		createInterfaceInRootPackage(DEFAULT_INTERFACE_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).createInterfaceRealization("InterfaceRealization",
				claimInterface(DEFAULT_INTERFACE_NAME))
		]
		assertClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertEquals(DEFAULT_INTERFACE_NAME, getClassifierFromTypeReference(javaClass.implements.head).name)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	@IncompatibleFeatures("RealizationSuffix")
	@IncompatibleFeatures("InterfacePrefix")
	def void testDeleteClassImplements() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		createInterfaceInRootPackage(DEFAULT_INTERFACE_NAME)
		createInterfaceInRootPackage(ADDITIONAL_INTERFACE_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).createInterfaceRealization("InterfaceRealization",
				claimInterface(DEFAULT_INTERFACE_NAME))
			claimClass(DEFAULT_CLASS_NAME).createInterfaceRealization("InterfaceRealization2",
				claimInterface(ADDITIONAL_INTERFACE_NAME))
		]
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).interfaceRealizations.remove(0)
		]
		assertClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertInterfaceWithNameInRootPackage(ADDITIONAL_INTERFACE_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertEquals(1, javaClass.implements.size)
			assertEquals(ADDITIONAL_INTERFACE_NAME, getClassifierFromTypeReference(javaClass.implements.head).name)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	@IncompatibleFeatures("RealizationSuffix")
	@IncompatibleFeatures("InterfacePrefix")
	def void testChangeInterfaceImplementer() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		createClassInRootPackage(ADDITIONAL_CLASS_NAME)
		createInterfaceInRootPackage(DEFAULT_INTERFACE_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).createInterfaceRealization("InterfaceRealization",
				claimInterface(DEFAULT_INTERFACE_NAME))
		]
		assertClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertClassWithNameInRootPackage(ADDITIONAL_CLASS_NAME)
		validateJavaView [
			val firstJavaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			val secondJavaClass = claimJavaClass(ADDITIONAL_CLASS_NAME)
			assertEquals(DEFAULT_INTERFACE_NAME, getClassifierFromTypeReference(firstJavaClass.implements.head).name)
			assertTrue(secondJavaClass.implements.nullOrEmpty)
		]
		changeUmlModel [
			val secondUmlClass = claimClass(ADDITIONAL_CLASS_NAME)
			val realization = claimClass(DEFAULT_CLASS_NAME).interfaceRealizations.claimOne
			realization.implementingClassifier = secondUmlClass
		]
		assertClassWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertClassWithNameInRootPackage(ADDITIONAL_CLASS_NAME)
		validateJavaView [
			val firstJavaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			val secondJavaClass = claimJavaClass(ADDITIONAL_CLASS_NAME)
			assertEquals(DEFAULT_INTERFACE_NAME, getClassifierFromTypeReference(secondJavaClass.implements.head).name)
			assertTrue(firstJavaClass.implements.nullOrEmpty)
		]
	}

	@Test
	def void testCreateDataType() {
		createDataTypeInRootPackage(DEFAULT_CLASS_NAME)
		assertSingleDataTypeWithNameInRootPackage(DEFAULT_CLASS_NAME)
	}

	@Test
	def void testMoveDataType() {
		createDataTypeInRootPackage(DEFAULT_CLASS_NAME)
		changeUmlModel [
			val umlDataType = claimDataType(DEFAULT_CLASS_NAME)
			packagedElements += UMLFactory.eINSTANCE.createPackage => [
				name = PACKAGE_NAME
				packagedElements += umlDataType
			]
		]
		assertSingleDataTypeWithNameInPackage(PACKAGE_NAME, DEFAULT_CLASS_NAME)
		assertNoClassifierWithNameInRootPackage(DEFAULT_CLASS_NAME)
		assertNoClassifierExistsInRootPackage()
	}

	@Test
	@RequiresFeatures(#["ClassCreation.Class", "RealizationSuffix"])
	@IncompatibleFeatures("InterfacePrefix")
	def void testUmlRealizationCreatedAppendsSuffix() {
		createClassInRootPackage(DEFAULT_CLASS_NAME)
		createInterfaceInRootPackage(DEFAULT_INTERFACE_NAME)
		changeUmlModel [
			claimClass(DEFAULT_CLASS_NAME).createInterfaceRealization("Realization",
				claimInterface(DEFAULT_INTERFACE_NAME))
		]
		validateUmlView [
			val umlClass = defaultUmlModel.claimClass(DEFAULT_CLASS_NAME + "Impl")
			assertEquals(DEFAULT_CLASS_NAME + "Impl", umlClass.name)
		]
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME + "Impl")
			assertEquals(DEFAULT_CLASS_NAME + "Impl", javaClass.name)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Interface")
	def void testUmlClassBecomesJavaInterface() {
		changeUmlModel [
			packagedElements += UMLFactory.eINSTANCE.createClass => [
				name = DEFAULT_CLASS_NAME
				visibility = VisibilityKind.PUBLIC_LITERAL
			]
		]
		validateJavaView [
			assertTrue(javaInterfaces.exists[name == DEFAULT_CLASS_NAME],
				"UML class must produce a Java interface when ClassCreation.Interface is active")
			assertFalse(javaClasses.exists[name == DEFAULT_CLASS_NAME],
				"no Java class must be produced when ClassCreation.Interface is active")
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Interface")
	def void testPropertyOnClassRealizedAsInterfaceCreatesConstantJavaField() {
		changeUmlModel [
			packagedElements += UMLFactory.eINSTANCE.createClass => [
				name = DEFAULT_CLASS_NAME
				visibility = VisibilityKind.PUBLIC_LITERAL
				ownedAttributes += UMLFactory.eINSTANCE.createProperty => [
					name = "someAttribute"
					visibility = VisibilityKind.PUBLIC_LITERAL
				]
			]
		]
		validateJavaView [
			val javaInterface = claimJavaInterface(DEFAULT_CLASS_NAME)
			val javaField = javaInterface.claimField("someAttribute")
			assertJavaModifiableStatic(javaField, true)
			assertJavaModifiableFinal(javaField, true)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Enum")
	def void testUmlClassBecomesJavaEnum() {
		changeUmlModel [
			packagedElements += UMLFactory.eINSTANCE.createClass => [
				name = DEFAULT_CLASS_NAME
				visibility = VisibilityKind.PUBLIC_LITERAL
			]
		]
		validateJavaView [
			val javaEnum = claimJavaEnum(DEFAULT_CLASS_NAME)
			assertEquals(DEFAULT_CLASS_NAME, javaEnum.name,
				"UML class must produce a Java enum with the same name when ClassCreation.Enum is active")
			assertFalse(javaClasses.exists[name == DEFAULT_CLASS_NAME],
				"no Java class must be produced when ClassCreation.Enum is active")
		]
	}

	@Test
	@RequiresFeatures("DataTypeCreation.Record")
	def void testUmlDataTypeBecomesFinalJavaClass() {
		createDataTypeInRootPackage(DEFAULT_CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DEFAULT_CLASS_NAME)
			assertJavaModifiableFinal(javaClass, true)
		]
	}

	static class BidirectionalTest extends UmlToJavaClassTest {
		override protected enableTransitiveCyclicChangePropagation() {
			true
		}
	}

}
