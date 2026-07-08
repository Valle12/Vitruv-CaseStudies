package tools.vitruv.applications.umljava.tests.java2uml

import org.eclipse.uml2.uml.VisibilityKind
import org.emftext.language.java.members.MembersFactory
import org.junit.jupiter.api.Test

import static tools.vitruv.applications.testutility.integration.UmlElementsTestAssertions.*
import static tools.vitruv.applications.util.temporary.java.JavaModificationUtil.*
import static tools.vitruv.applications.util.temporary.java.JavaStandardType.*

import static extension tools.vitruv.applications.testutility.uml.UmlQueryUtil.*
import static extension tools.vitruv.applications.umljava.tests.util.JavaQueryUtil.*
import static extension tools.vitruv.applications.util.temporary.java.JavaModifierUtil.*

class JavaToUmlInterfaceAttributeTest extends AbstractJavaToUmlTest {
	static val INTERFACE_NAME = "InterfaceName"
	static val ATTRIBUTE_NAME = "attributeName"

	@Test
	def void testCreateFieldInInterface() {
		createJavaInterfaceInRootPackage(INTERFACE_NAME)
		changeJavaView [
			claimJavaInterface(INTERFACE_NAME) => [
				members += MembersFactory.eINSTANCE.createField => [
					name = ATTRIBUTE_NAME
					typeReference = createJavaPrimitiveType(INT)
					makePublic
					static = true
					final = true
				]
			]
		]
		assertSingleInterfaceWithNameInRootPackage(INTERFACE_NAME)
		validateUmlView [
			val umlInterface = defaultUmlModel.claimInterface(INTERFACE_NAME)
			val umlAttribute = umlInterface.claimAttribute(ATTRIBUTE_NAME)
			assertUmlNamedElementHasVisibility(umlAttribute, VisibilityKind.PUBLIC_LITERAL)
		]
	}

	static class BidirectionalTest extends JavaToUmlInterfaceAttributeTest {
		override protected enableTransitiveCyclicChangePropagation() {
			true
		}
	}

}
