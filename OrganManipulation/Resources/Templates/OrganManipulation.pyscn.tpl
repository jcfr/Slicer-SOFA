from stlib3.scene import MainHeader, ContactHeader
from stlib3.solver import DefaultSolver
from stlib3.physics.deformable import ElasticMaterialObject
from stlib3.physics.rigid import Floor
#from stlib3.visuals import ShowGrid
from splib3.numerics import Vec3

def createScene(rootNode):
    MainHeader(rootNode, plugins=[
        "Sofa.Component.IO.Mesh",
        "Sofa.Component.LinearSolver.Direct",
        "Sofa.Component.LinearSolver.Iterative",
        "Sofa.Component.Mapping.Linear",
        "Sofa.Component.Mass",
        "Sofa.Component.ODESolver.Backward",
        "Sofa.Component.Setting",
        "Sofa.Component.SolidMechanics.FEM.Elastic",
        "Sofa.Component.StateContainer",
        "Sofa.Component.Topology.Container.Dynamic",
        "Sofa.Component.Visual",
        "Sofa.GL.Component.Rendering3D",
        "Sofa.Component.AnimationLoop",
        "Sofa.Component.Collision.Detection.Algorithm",
        "Sofa.Component.Collision.Detection.Intersection",
        "Sofa.Component.Collision.Geometry",
        "Sofa.Component.Collision.Response.Contact",
        "Sofa.Component.Constraint.Lagrangian.Solver",
        "Sofa.Component.Constraint.Lagrangian.Correction",
        "Sofa.Component.LinearSystem",
        "Sofa.Component.MechanicalLoad",
        "MultiThreading",
        "Sofa.Component.SolidMechanics.Spring",
        "Sofa.Component.Constraint.Lagrangian.Model",
        "Sofa.Component.Mapping.NonLinear",
        "Sofa.Component.Topology.Container.Constant",
        "Sofa.Component.Topology.Mapping",
        "SofaIGTLink"
    ], dt=0.01, gravity=[9810, 0, 0])

    rootNode.addObject('VisualStyle', displayFlags='showVisualModels showForceFields')
    rootNode.addObject('BackgroundSetting', color=[0.8, 0.8, 0.8, 1])
    rootNode.addObject('DefaultAnimationLoop', name="FreeMotionAnimationLoop", parallelODESolving=True)

    rootNode.addObject('iGTLinkClient', name="iGTLClient", sender=True, hostname="127.0.0.1", port=18944)

    #Server receiving attachment point position
    rootNode.addObject('iGTLinkServer',name="iGTLServer", sender="false", port="18945")
    rootNode.addObject('iGTLinkPointMessage', name="AttachPointMessage", iGTLink="@iGTLServer",
                        enableRadius="false",
                        enableLabels="false",
                        enableGroups="false",
                        enableOwners="false")

    attachmentRestPos = "0.5 0.05 0.05" #To be modified with the position on the mesh defined by the user on Slicer
    attachPointNode = rootNode.addChild('AttachPoint')
    attachPointNode.addObject('PointSetTopologyContainer', name="Container")
    attachPointNode.addObject('PointSetTopologyModifier', name="Modifier")
    attachPointNode.addObject('MechanicalObject', name="mstate", template="Vec3d", position=attachmentRestPos, drawMode="2", showObjectScale="0.01", showObject="false")
    attachPointNode.addObject('EngineToMState', state="@mstate", position="@../AttachPointMessage.points", template="Vec3d")

    meshNode = rootNode.addChild('Mesh')
    meshNode.addObject('EulerImplicitSolver', firstOrder=False, rayleighMass=0.1, rayleighStiffness=0.1)
    meshNode.addObject('SparseLDLSolver', name="precond", template="CompressedRowSparseMatrixd", parallelInverseProduct=True)
    meshNode.addObject('MeshVTKLoader', name="loader", filename="right-long-mesh-low.vtk")
    meshNode.addObject('TetrahedronSetTopologyContainer', name="Container", src="@loader")
    meshNode.addObject('TetrahedronSetTopologyModifier', name="Modifier")
    meshNode.addObject('MechanicalObject', name="mstate", template="Vec3f")
    meshNode.addObject('TetrahedronFEMForceField', name="FEM", youngModulus=1.5, poissonRatio=0.45, method="large")
    meshNode.addObject('MeshMatrixMass', totalMass=1)
    meshNode.addObject('iGTLinkPolyDataMessage', name="SOFAMesh", iGTLink="@../iGTLClient",
                       points="@mstate.position",
                       enableIndices=False,
                       enableEdges=False,
                       enableTriangles=False,
                       enableTetra=False,
                       enableHexa=False)

    fixedROI = meshNode.addChild('FixedROI')
    fixedROI.addObject('BoxROI', template="Vec3", box=[0, 170, 0, -48, 80, -300, 0, 220, 0, -30, 170, -300], drawBoxes=True, position="@../mstate.rest_position", name="FixedROI", computeTriangles=False, computeTetrahedra=False, computeEdges=False)
    fixedROI.addObject('FixedConstraint', indices="@FixedROI.indices")

    collisionNode = meshNode.addChild('Collision')
    collisionNode.addObject('TriangleSetTopologyContainer', name="Container")
    collisionNode.addObject('TriangleSetTopologyModifier', name="Modifier")
    collisionNode.addObject('Tetra2TriangleTopologicalMapping', input="@../Container", output="@Container")
    collisionNode.addObject('MechanicalObject',name="dofs", rest_position="@../mstate.rest_position")
    collisionNode.addObject('TriangleCollisionModel',name="Surface", proximity="0.02")
    collisionNode.addObject('IdentityMapping', name="SurfaceMapping")


    meshAttachmentNode = meshNode.addChild('AttachPoint')
    meshAttachmentNode.addObject('PointSetTopologyContainer', name="Container")
    meshAttachmentNode.addObject('PointSetTopologyModifier', name="Modifier")
    meshAttachmentNode.addObject('MechanicalObject', name="mstate", template="Vec3d", position=attachmentRestPos, drawMode="1", showObjectScale="0.01", showColor="0 1 0",  showObject="false")
    #This object defines the spring attaching the mesh point to the one recived from slicer stiffness. The 'reactionTime'
    # parameter defines the timelaps without update of the received position required to deactivate this spring (this
    # enables a releasing mechanism)
    meshAttachmentNode.addObject('UserInteractionController', name="UIC", inStiffness="10000", reactionTime="50", position="@../../AttachPointMessage.points")
    meshAttachmentNode.addObject('RestShapeSpringsForceField', stiffness='@UIC.outStiffness',  external_rest_shape='@../../AttachPoint/mstate', points='0', external_points='0')
    meshAttachmentNode.addObject('BarycentricMapping')


