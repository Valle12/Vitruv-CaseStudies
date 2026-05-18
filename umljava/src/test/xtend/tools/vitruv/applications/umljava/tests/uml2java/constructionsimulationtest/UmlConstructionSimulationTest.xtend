package tools.vitruv.applications.umljava.tests.uml2java.constructionsimulationtest

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.uml2.uml.Model
import org.junit.jupiter.api.Test
import tools.vitruv.applications.umljava.tests.uml2java.AbstractUmlToJavaTest
import tools.vitruv.applications.umljava.tests.util.conditional.IncompatibleFeatures
import tools.vitruv.applications.umljava.tests.util.conditional.RequiresFeatures

import static extension edu.kit.ipd.sdq.commons.util.org.eclipse.emf.ecore.resource.ResourceUtil.getFirstRootEObject

@RequiresFeatures("ClassCreation.Class")
class UmlConstructionSimulationTest extends AbstractUmlToJavaTest {
	static val RESOURCES_FOLDER = "src/test/resources/"

	override void setup() {}

	@Test
	@IncompatibleFeatures("RealizationSuffix")
	def void testSyntheticModel1() {
		transformUmlModelAndValidateJavaCode("synthetic/model1")
	}

	@Test
	@IncompatibleFeatures("RealizationSuffix")
	def void testSyntheticModel2() {
		transformUmlModelAndValidateJavaCode("synthetic/model2")
	}

	@Test
	@IncompatibleFeatures("RealizationSuffix")
	def void testSuresh519MyProjectModel() {
		// UML model from "myproject" by suresh519:
		// https://repository.genmymodel.com/suresh519/MyProject (12.5.2017)
		transformUmlModelAndValidateJavaCode("suresh519/uml/MyProject")
	}

	@Test
	@IncompatibleFeatures("RealizationSuffix")
	// TODO The orhanobut model contains interfaces whose names don't start with 'I' (LogAdapter,Printer) trips up tests
	// Potential migration case
	@IncompatibleFeatures("InterfacePrefix")
	def void testOrhanobutLoggerModel() {
		// UML model from the logger project by orhan obut:
		// https://github.com/orhanobut/logger (12.5.2017)
		transformUmlModelAndValidateJavaCode("orhanobut/uml/model")
	}

	private def void transformUmlModelAndValidateJavaCode(String modelFileName) {
		transformUmlModelFileAndValidateJavaCode(RESOURCES_FOLDER + modelFileName + "." + MODEL_FILE_EXTENSION)
	}

	private def void transformUmlModelFileAndValidateJavaCode(String modelPath) {
		val resourceSet = new ResourceSetImpl()
		val model = resourceSet.getResource(URI.createFileURI(modelPath), true).firstRootEObject as Model => [
			name = UML_MODEL_NAME
		]
		EcoreUtil.resolveAll(model)
		changeJavaView [
			createAndRegisterRoot(model, UML_MODEL_NAME.projectModelPath.uri)
		]
		for (class : model.packagedElements.filter(org.eclipse.uml2.uml.Class).toList) {
			assertClassWithNameInRootPackage(class.name)
		}
		for (interface : model.packagedElements.filter(org.eclipse.uml2.uml.Interface).toList) {
			assertInterfaceWithNameInRootPackage(interface.name)
		}
		for (enum : model.packagedElements.filter(org.eclipse.uml2.uml.Enumeration).toList) {
			assertEnumWithNameInRootPackage(enum.name)
		}
		resourceSet.resources.forEach[unload()]
		resourceSet.resources.clear()
	}

	static class BidirectionalTest extends UmlConstructionSimulationTest {
		override protected enableTransitiveCyclicChangePropagation() {
			true
		}
	}

}
