package tools.vitruv.applications.umljava.tests.uml2java

import org.eclipse.uml2.uml.Model
import org.eclipse.uml2.uml.Operation
import org.eclipse.uml2.uml.VisibilityKind
import org.emftext.language.java.members.ClassMethod
import org.emftext.language.java.members.Constructor
import org.emftext.language.java.parameters.Parameter
import org.emftext.language.java.references.IdentifierReference
import org.emftext.language.java.references.ReferencesFactory
import org.emftext.language.java.statements.ExpressionStatement
import org.emftext.language.java.statements.StatementsFactory
import org.emftext.language.java.types.TypesFactory
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.EnumSource
import tools.vitruv.applications.util.temporary.java.JavaVisibility

import static org.hamcrest.CoreMatchers.*
import static org.hamcrest.MatcherAssert.assertThat
import static org.junit.jupiter.api.Assertions.assertEquals
import static org.junit.jupiter.api.Assertions.assertFalse
import static org.junit.jupiter.api.Assertions.assertTrue
import static tools.vitruv.applications.testutility.integration.JavaElementsTestAssertions.*
import static tools.vitruv.applications.util.temporary.java.JavaModificationUtil.*
import static tools.vitruv.applications.util.temporary.java.JavaModifierUtil.getJavaVisibilityConstantFromUmlVisibilityKind

import static extension tools.vitruv.applications.testutility.uml.UmlQueryUtil.*
import static extension tools.vitruv.applications.umljava.tests.util.JavaQueryUtil.*
import tools.vitruv.applications.umljava.tests.util.conditional.IncompatibleFeatures
import tools.vitruv.applications.umljava.tests.util.conditional.RequiresFeatures

/**
 * A test class to test class methods and its traits.
 */
class UmlToJavaClassMethodTest extends AbstractUmlToJavaTest {
	static val CLASS_NAME = "ClassName"
	static val CLASS_NAME_2 = "ClassName2"
	static val TYPE_CLASS_NAME = "TypeName"
	static val OPERATION_NAME = "classMethod"
	static val OPERATION_RENAME = "classMethodRenamed"
	static val DATATYPE_NAME = "DataTypeName"
	static val DATATYPE_NAME_2 = "DataTypeName2"

	/**
	 * Tests if creating a UML operation also causes the creating of an corresponding
	 * Java method.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testCreateClassMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		assertSingleClassWithNameInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			val javaMethod = javaClass.claimClassMethod(OPERATION_NAME)
			assertJavaClassMethodTraits(javaMethod, OPERATION_NAME, JavaVisibility.PUBLIC,
				TypesFactory.eINSTANCE.createVoid, false, false, null, javaClass)
		]
	}

	/**
	 * Tests the change of the UML method return type. Checks if
	 * the corresponding Java method adapted the corresponding type.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testChangeReturnType() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		createClassInRootPackage(TYPE_CLASS_NAME)
		changeMethod(CLASS_NAME, OPERATION_NAME) [ model, operation |
			operation.type = model.claimClass(TYPE_CLASS_NAME)
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaMethod = claimJavaClass(CLASS_NAME).claimClassMethod(OPERATION_NAME)
			val javaTypeClass = claimJavaClass(TYPE_CLASS_NAME)
			assertJavaElementHasTypeRef(javaMethod, createNamespaceClassifierReference(javaTypeClass))
		]
	}

	/**
	 * Tests if renaming a method is correctly reflected on the Java side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testRenameMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeMethod(CLASS_NAME, OPERATION_NAME) [
			name = OPERATION_RENAME
		]
		assertSingleClassWithNameInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			assertJavaMemberContainerDontHaveMember(javaClass, OPERATION_NAME)
		]
	}

	/**
	 * Tests if deleting a method is correctly reflected on the Java side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testDeleteMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeMethod(CLASS_NAME, OPERATION_NAME) [
			destroy()
		]
		assertSingleClassWithNameInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			assertJavaMemberContainerDontHaveMember(javaClass, OPERATION_NAME)
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testMoveMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		createClassInRootPackage(CLASS_NAME_2)
		changeMethod(CLASS_NAME, OPERATION_NAME) [ model, method |
			model.claimClass(CLASS_NAME_2).ownedOperations += method
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		assertClassWithNameInRootPackage(CLASS_NAME_2)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			val javaClass2 = claimJavaClass(CLASS_NAME_2)
			assertJavaMemberContainerDontHaveMember(javaClass, OPERATION_NAME)
			assertThat(CLASS_NAME_2 + " must have operation " + OPERATION_NAME,
				javaClass2.getMembersByName(OPERATION_NAME).toSet, is(not(emptySet)))
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testMoveMethodWithImplementation() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		createClassInRootPackage(CLASS_NAME_2)
		changeJavaView [
			claimJavaClass(CLASS_NAME) => [
				claimClassMethod(OPERATION_NAME) => [
					statements += StatementsFactory.eINSTANCE.createReturn
				]
			]
		]
		changeMethod(CLASS_NAME, OPERATION_NAME) [ model, method |
			model.claimClass(CLASS_NAME_2).ownedOperations += method
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		assertClassWithNameInRootPackage(CLASS_NAME_2)
		validateJavaView [
			claimJavaClass(CLASS_NAME_2) => [
				claimClassMethod(OPERATION_NAME) => [
					assertThat("there has to be a return statement from moving the method", statements,
						not(is(emptyList)))
				]
			]
		]
	}

	/**
	 * Tests if setting a method static correctly reflected on the Java side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testStaticMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [isStatic = true], [
			assertJavaModifiableStatic(it, true)
		])
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [isStatic = false], [
			assertJavaModifiableStatic(it, false)
		])
	}

	/**
	 * Tests if setting a method final correctly reflected on the Java side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testFinalMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [isLeaf = true], [
			assertJavaModifiableFinal(it, true)
		])
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [isLeaf = false], [
			assertJavaModifiableFinal(it, false)
		])
	}

	/**
	 * Tests if setting a method abstract is correctly reflected on the Java side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def testAbstractMethod() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [isAbstract = true], [
			assertJavaModifiableAbstract(it, true)
		])
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [isAbstract = false], [
			assertJavaModifiableAbstract(it, false)
		])
	}

	/**
	 * Tests if visibility changes are propagated to the Java method.
	 */
	@ParameterizedTest
	@EnumSource(value=VisibilityKind, names=#["PUBLIC_LITERAL"], mode=EnumSource.Mode.EXCLUDE)
	@RequiresFeatures("ClassCreation.Class")
	def void testMethodVisibility(VisibilityKind visibility) {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeAndCheckPropertyOfAttribute(CLASS_NAME, OPERATION_NAME, [it.visibility = visibility], [
			assertJavaModifiableHasVisibility(it, getJavaVisibilityConstantFromUmlVisibilityKind(visibility))
		])
	}

	/**
	 * Tests the creation of a method that act as constructor and checks if a 
	 * constructor is created on the Java side.
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testCreateConstructor() {
		createClassWithOperation(CLASS_NAME, CLASS_NAME)
		assertSingleClassWithNameInRootPackage(CLASS_NAME)
		validateJavaView [
			claimJavaClass(CLASS_NAME).claimConstructor()
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testMoveConstructor() {
		createClassWithOperation(CLASS_NAME, CLASS_NAME)
		createClassInRootPackage(CLASS_NAME_2)
		changeMethod(CLASS_NAME, CLASS_NAME) [ model, method |
			model.claimClass(CLASS_NAME_2).ownedOperations += method => [
				name = CLASS_NAME_2
			]
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		assertClassWithNameInRootPackage(CLASS_NAME_2)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			val javaClass2 = claimJavaClass(CLASS_NAME_2)
			javaClass2.claimConstructor()
			assertJavaMemberContainerDontHaveMember(javaClass, CLASS_NAME)
			assertJavaMemberContainerDontHaveMember(javaClass, CLASS_NAME_2)
			assertJavaMemberContainerDontHaveMember(javaClass2, CLASS_NAME)
			assertThat(javaClass2.getMembersByName(CLASS_NAME_2).toSet, is(not(emptySet)))
		]
	}

	/**
	 * Same as testMoveConstructor but the order of move and rename is switched
	 */
	@Test
	@RequiresFeatures("ClassCreation.Class")
	def void testMoveConstructor2() {
		createClassWithOperation(CLASS_NAME, CLASS_NAME)
		createClassInRootPackage(CLASS_NAME_2)
		changeMethod(CLASS_NAME, CLASS_NAME) [ model, method |
			method => [
				name = CLASS_NAME_2
			]
			model.claimClass(CLASS_NAME_2).ownedOperations += method
		]
		assertClassWithNameInRootPackage(CLASS_NAME)
		assertClassWithNameInRootPackage(CLASS_NAME_2)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			val javaClass2 = claimJavaClass(CLASS_NAME_2)
			javaClass2.claimConstructor()
			assertJavaMemberContainerDontHaveMember(javaClass, CLASS_NAME)
			assertJavaMemberContainerDontHaveMember(javaClass, CLASS_NAME_2)
			assertJavaMemberContainerDontHaveMember(javaClass2, CLASS_NAME)
			assertThat(javaClass2.getMembersByName(CLASS_NAME_2).toSet, is(not(emptySet)))
		]
	}

	/**
	 * Checks if method creating in data types is reflected in the corresponding Java class.
	 */
	@Test
	def void testCreateMethodInDataType() {
		createDataTypeWithOperation(DATATYPE_NAME, OPERATION_NAME)
		assertSingleDataTypeWithNameInRootPackage(DATATYPE_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DATATYPE_NAME)
			val javaMethod = javaClass.claimClassMethod(OPERATION_NAME)
			assertJavaClassMethodTraits(javaMethod, OPERATION_NAME, JavaVisibility.PUBLIC,
				TypesFactory.eINSTANCE.createVoid, false, false, null, javaClass)
		]
	}

	/**
	 * Tests the deletion of methods in data types and if the deletion is
	 * propagated to the Java model.
	 */
	@Test
	def void testDeleteMethodInDataType() {
		createDataTypeWithOperation(DATATYPE_NAME, OPERATION_NAME)
		changeUmlModel [
			claimDataType(DATATYPE_NAME) => [
				claimOperation(OPERATION_NAME) => [
					destroy()
				]
			]
		]
		assertSingleDataTypeWithNameInRootPackage(DATATYPE_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(DATATYPE_NAME)
			assertJavaMemberContainerDontHaveMember(javaClass, OPERATION_NAME)
		]
	}

	@Test
	def void testMoveMethodInDataType() {
		createDataTypeWithOperation(DATATYPE_NAME, OPERATION_NAME)
		createDataTypeInRootPackage(DATATYPE_NAME_2)
		changeUmlModel [
			val operation = claimDataType(DATATYPE_NAME).claimOperation(OPERATION_NAME)
			claimDataType(DATATYPE_NAME_2) => [
				ownedOperations += operation
			]
		]
		assertDataTypeWithNameInRootPackage(DATATYPE_NAME)
		assertDataTypeWithNameInRootPackage(DATATYPE_NAME_2)
		validateJavaView [
			val javaClass = claimJavaClass(DATATYPE_NAME)
			val javaClass2 = claimJavaClass(DATATYPE_NAME_2)
			assertJavaMemberContainerDontHaveMember(javaClass, OPERATION_NAME)
			assertThat(javaClass2.getMembersByName(OPERATION_NAME).toSet, is(not(emptySet)))
		]
	}

	private def void createClassWithOperation(String className, String operationName) {
		createClassInRootPackage(className)
		changeUmlModel [
			claimClass(className) => [
				createOwnedOperation(operationName, null, null, null)
			]
		]
	}

	private def void createDataTypeWithOperation(String dataTypeName, String operationName) {
		createDataTypeInRootPackage(dataTypeName)
		changeUmlModel [
			claimDataType(dataTypeName) => [
				createOwnedOperation(operationName, null, null, null)
			]
		]
	}

	private def changeMethod(String className, String methodName, (Operation)=>void changeFunction) {
		changeMethod(className, methodName, [model, operation|changeFunction.apply(operation)])
	}

	private def changeMethod(String className, String methodName, (Model, Operation)=>void changeFunction) {
		changeUmlModel [
			val model = it
			claimClass(className) => [
				claimOperation(methodName) => [
					changeFunction.apply(model, it)
				]
			]
		]
	}

	private def void changeAndCheckPropertyOfAttribute(String className, String methodName,
		(Operation)=>void changeUmlMethod, (ClassMethod)=>void validateJavaMethod) {
		changeMethod(className, methodName) [
			changeUmlMethod.apply(it)
		]
		assertSingleClassWithNameInRootPackage(className)
		validateJavaView [
			val javaMethod = claimJavaClass(className).claimClassMethod(methodName)
			validateJavaMethod.apply(javaMethod)
		]
	}

	@Test
	@RequiresFeatures(#["ClassCreation.Class", "MethodStaticCall"])
	def void testMethodStaticCallMakesMethodFinal() {
		createClassWithOperation(CLASS_NAME, OPERATION_NAME)
		changeMethod(CLASS_NAME, OPERATION_NAME) [ method |
			method.isStatic = true
		]
		validateJavaView [
			val javaMethod = claimJavaClass(CLASS_NAME).claimClassMethod(OPERATION_NAME)
			assertJavaModifiableFinal(javaMethod, true)
		]
	}

	@Test
	@RequiresFeatures(#["ClassCreation.Class", "MethodStaticCall"])
	def void testMethodStaticCallRewritesCrossClassReceiver() {
		val ownerName = "OwnerClass"
		val callerName = "CallerClass"
		val targetMethodName = "doWork"
		val callerMethodName = "callIt"
		val paramName = "owner"

		createClassInRootPackage(ownerName)
		changeUmlModel [
			claimClass(ownerName) => [
				createOwnedOperation(targetMethodName, null, null, null)
			]
		]
		createClassInRootPackage(callerName)
		changeUmlModel [
			val ownerUml = claimClass(ownerName)
			claimClass(callerName) => [
				createOwnedOperation(callerMethodName, null, null, null) => [
					createOwnedParameter(paramName, ownerUml)
				]
			]
		]

		// Inject `owner.doWork();` into the caller method so the rewrite has something to fix.
		changeJavaView [
			val targetJavaMethod = claimJavaClass(ownerName).claimClassMethod(targetMethodName)
			claimJavaClass(callerName).claimClassMethod(callerMethodName) => [
				val javaParam = claimParameter(paramName)
				val paramRef = ReferencesFactory.eINSTANCE.createIdentifierReference => [
					target = javaParam
				]
				val methodCall = ReferencesFactory.eINSTANCE.createMethodCall => [
					target = targetJavaMethod
				]
				paramRef.setNext(methodCall)
				statements += StatementsFactory.eINSTANCE.createExpressionStatement => [
					expression = paramRef
				]
			]
		]
		validateJavaView [
			val expr = ((claimJavaClass(callerName).claimClassMethod(callerMethodName).statements.head
				as ExpressionStatement).expression) as IdentifierReference
			assertTrue(expr.target instanceof Parameter,
				"Sanity: before isStatic=true the call receiver should still be the parameter")
		]

		changeMethod(ownerName, targetMethodName) [ op |
			op.isStatic = true
		]

		validateJavaView [
			val javaOwner = claimJavaClass(ownerName)
			val expr = ((claimJavaClass(callerName).claimClassMethod(callerMethodName).statements.head
				as ExpressionStatement).expression) as IdentifierReference
			assertEquals(javaOwner, expr.target,
				"After MethodStaticCall, the instance receiver must be rewritten to the owner Java class")
		]
	}

	@Test
	@RequiresFeatures(#["ClassCreation.Class", "ConstructorCreation"])
	def void testConstructorCreationAddsDefaultConstructor() {
		createClassInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			assertFalse(javaClass.members.filter(Constructor).empty,
				"a default constructor must be added when ConstructorCreation is active")
		]
	}

	@Test
	@RequiresFeatures("ClassCreation.Class")
	@IncompatibleFeatures("ConstructorCreation")
	def void testNoDefaultConstructorWhenFeatureInactive() {
		createClassInRootPackage(CLASS_NAME)
		validateJavaView [
			val javaClass = claimJavaClass(CLASS_NAME)
			assertTrue(javaClass.members.filter(Constructor).empty,
				"no default constructor must be added when ConstructorCreation is inactive")
		]
	}

	static class BidirectionalTest extends UmlToJavaClassMethodTest {
		override protected enableTransitiveCyclicChangePropagation() {
			true
		}
	}

}
