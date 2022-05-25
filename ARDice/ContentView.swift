//
//  ContentView.swift
//  ARDice
//
//  Created by Luca Hummel on 25/05/22.
//

import SwiftUI
import ARKit
import RealityKit
import FocusEntity

struct RealityKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let view = ARView()
        
        // Iniciar sessão de AR
        let session = view.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)
        
        // overlay para comecar
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)
        
        // debug options
#if DEBUG
        //view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
#endif
        
        // ARSession delegates
        context.coordinator.view = view
        session.delegate = context.coordinator
        
        // Toques
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap)))
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        var diceEntity: ModelEntity?

        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            debugPrint("Ancoras adicionas na sena: ", anchors)
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            if let diceEntity = self.diceEntity {
                // roll the dice on 2nd tap
                diceEntity.addForce([0, 4, 0], relativeTo: nil)
                diceEntity.addTorque([Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4)], relativeTo: nil)
            } else {
                // Criar nova ancora para adicionar content
                let anchor = AnchorEntity()
                view.scene.anchors.append(anchor)
                
                // Adicionar uma entidade Box com material azul
                //            let box = MeshResource.generateBox(size: 0.05, cornerRadius: 0.005)
                //            let material = SimpleMaterial(color: .blue, isMetallic: true)
                //            let diceEntity = ModelEntity(mesh: box, materials: [material])
                //            diceEntity.position = focusEntity.position
                
                // Adicionar modelo de dado
                let diceEntity = try! ModelEntity.loadModel(named: "Dice")
                diceEntity.scale = [0.1, 0.1, 0.1]
                diceEntity.position = focusEntity.position
                
                // Adicionar fisica
                let size = diceEntity.visualBounds(relativeTo: diceEntity).extents
                let boxShape = ShapeResource.generateBox(size: size)
                diceEntity.collision = CollisionComponent(shapes: [boxShape])
                diceEntity.physicsBody = PhysicsBodyComponent(massProperties: .init(shape: boxShape, mass: 50), material: nil, mode: .dynamic)
                
                // adicionar plano
                let planeMesh = MeshResource.generatePlane(width: 2, depth: 2)
                let material = SimpleMaterial(color: .init(white: 1, alpha: 0.1), isMetallic: false)
                let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
                planeEntity.position = focusEntity.position
                planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
                planeEntity.collision = CollisionComponent(shapes: [.generateBox(width: 2, height: 0.001, depth: 2)])
                
                anchor.addChild(planeEntity)
                
                self.diceEntity = diceEntity
                anchor.addChild(diceEntity)
            }
        }
    }
}



struct ContentView: View {
    var body: some View {
        RealityKitView().ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
