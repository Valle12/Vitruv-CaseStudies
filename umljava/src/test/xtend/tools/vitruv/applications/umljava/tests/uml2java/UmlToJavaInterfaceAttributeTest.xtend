package tools.vitruv.applications.umljava.tests.uml2java

import org.eclipse.uml2.uml.UMLFactory
import org.eclipse.uml2.uml.VisibilityKind
import org.junit.jupiter.api.Test
import tools.vitruv.applications.util.temporary.java.JavaVisibility
import tools.vitruv.applications.umljava.tests.util.conditional.RequiresFeatures

import static org.junit.jupiter.api.Assertions.assertTrue
import static tools.vitruv.applications.testutility.integration.JavaElementsTestAssertions.*
import static tools.vitruv.applications.util.temporary.java.JavaMemberAndParameterUtil.*

import static extension tools.vitruv.applications.testutility.uml.UmlQueryUtil.*
import static extension tools.vitruv.applications.umljava.tests.util.JavaQueryUtil.*

class UmlToJavaInterfaceAttributeTest extends AbstractUmlToJavaTest {
	static val INTERFACE_NAME = "InterfaceName"
	static val CLASS_NAME = "ClassName"
	static val ATTRIBUTE_NAME = "attributeName"

	@Test
	def void testCreateAttributeInInterface() {
		createInterfaceInRootPackage(INTERFACE_NAME)
		val primitiveType = loadUmlPrimitiveType("int")
		changeUmlModel [
			claimInterface(INTERFACE_NAME) => [
				ownedAttributes += UMLFactory.eINSTANCE.createProperty => [
					name = ATTRIBUTE_NAME
					visibility = VisibilityKind.PUBLIC_LITERAL
					type = primitiveType
				]
			]
		]
		assertInterfaceWithNameInRootPackage(INTERFACE_NAME)
		validateJavaView [
			val javaInterface = claimJavaInterface(INTERFACE_NAME)
			val javaField = javaInterface.claimField(ATTRIBUTE_NAME)
			assertJavaModifiableHasVisibility(javaField, JavaVisibility.PUBLIC)
			assertJavaModifiableStatic(javaField, true)
			assertJavaModifiableFinal(javaField, true)
			assertTrue(getJavaGettersOfAttribute(javaField).empty,
				"an interface constant must not have a generated getter")
			assertTrue(getJavaSettersOfAttribute(javaField).empty,
				"an interface constant must not have a generated setter")
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Interface")
	def void testCreateAttributeInClassRealizedAsInterface() {
		changeUmlModel [
			packagedElements += UMLFactory.eINSTANCE.createClass => [
				name = CLASS_NAME
			]
		]
		val primitiveType = loadUmlPrimitiveType("int")
		changeUmlModel [
			claimClass(CLASS_NAME) => [
				ownedAttributes += UMLFactory.eINSTANCE.createProperty => [
					name = ATTRIBUTE_NAME
					visibility = VisibilityKind.PUBLIC_LITERAL
					type = primitiveType
				]
			]
		]
		validateJavaView [
			val javaInterface = claimJavaInterface(CLASS_NAME)
			val javaField = javaInterface.claimField(ATTRIBUTE_NAME)
			assertJavaModifiableHasVisibility(javaField, JavaVisibility.PUBLIC)
			assertJavaModifiableStatic(javaField, true)
			assertJavaModifiableFinal(javaField, true)
		]
	}

	static class BidirectionalTest extends UmlToJavaInterfaceAttributeTest {
		override protected enableTransitiveCyclicChangePropagation() {
			true
		}
	}

}
