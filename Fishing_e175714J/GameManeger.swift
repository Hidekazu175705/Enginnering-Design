//
//  GameManeger.swift
//  Fishing_Demo
//
//  Created by 仲西 智章 on 2019/11/29.
//  Copyright © 2019 Spike. All rights reserved.
//

import ARKit
import Foundation
import CoreMotion
import SceneKit

//timer
class GameManager{
    init(){
        scene=Casting(status: GameStatus(),visual: self.visual)//一旦sceneに今の呼び出している処理のクラスを入れる。
        Timer.scheduledTimer(
            timeInterval: 1/60,//実行する時間
            target: self,
            selector: #selector(self.UpdateValue),//実行関数
            userInfo: nil,
            repeats: true
        )
    }
    var scene:GameScene//呼び出しているクラスは更新される為、verで定義する。
    let visual=Visualizer()
    let ui = UIController()

    //Timerで実行する処理
    @objc func UpdateValue() {
        // 1/60秒ごとに実行する処理、UIControlerから値を受け取って現在の値を代入
        scene.update(cameraNode:ui.sendCamera(),acc:ui.deviceAccelarate(),gyro:ui.deviceRotation())
        visual.update()
        
        if let next_scene = scene.next() {
            scene = next_scene
        }
        //Timer.invalidate() //Timerの終了
    }
}


class GameStatus{
    init(){
        HitCondition=0
        FightResult=true
        proend=0
    }
    //魚の情報<かかった瞬間に決定される(未実装)
    //かかり具合<-智章が書き換える　＜＜ケンタが参照
    var HitCondition:Int
    //釣れたか釣れてないか <- ケンタが決定
    var FightResult:Bool
    
    //cast,Hooking,Fightの処理を終えたかを受け取る
    var proend:Int
}

class GameScene {
    init(status:GameStatus,visual:Visualizer){
        self.status=status
        self.visual=visual
    }
    var status : GameStatus
    var visual : Visualizer
    func tap(){}
    func release(){}
    func update(cameraNode:SCNNode,acc:SCNVector3,gyro:SCNVector3){
        fatalError()
    }
    func next() -> GameScene? {
        return nil
    }
}

class Visualizer{
    //平面ノードの位置
    //平面までの距離を返す関数
    //BaseNode(child:float,plane)
    //anchorの位置にBaseNodeを移動
    //rendererからVisualizerを呼び出す(BaseNode の移動)
    //SceneNodeのrootNodeにadd
    
    init(){
        //scene = onechance使う(よく分かってない)
        let objGeometry = SCNSphere(radius: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.diffuse.intensity = 0.8;
        objGeometry.materials = [material]
        floatNode=SCNNode(geometry: objGeometry)
       /*
        let planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
        geometry?.materials = [planeMaterial]
        planeNode=SCNNode(geometry: planeGeometry)
        */
        //scene.rootNode.addChildNode(BaseNode)?
    }
    //This is the function to get camera position and to define the initial position of floatNode
    //This function requires the camera position as Index(World coordinates)
    //移動する距離を引数にする. vを利用して上手いこと移動
    
    //rendererから呼ばれる関数
    func setBasePos(anchor: ARPlaneAnchor){
        let x = CGFloat(anchor.center.x)
        let y = CGFloat(anchor.center.y)
        let z = CGFloat(anchor.center.z)
        BaseNode.position = SCNVector3(x,y,z)
    }
    
    func moveFloat(to how:SCNVector3){
        let oldPos:SCNVector3 = floatPos
        while(oldPos.x + how.x != floatPos.x && oldPos.y + how.y != floatPos.y && oldPos.z + how.z != floatPos.z){
            //how割る30が必要->60fpsなら0.5秒で移動
            setFloatVel(how)
        }
        setFloatVel(SCNVector3(0,0,0))
    }

    func setInitialPos(to campos:SCNVector3){
        floatNode.position = campos
    }
    
    func setFloatVel(_ vel:SCNVector3){
        floatVel = vel
    }
    //It is unimplemented to calculate gravity yet
    func update(){
        let newx = floatPos.x + floatVel.x
        let newy = floatPos.y + floatVel.y
        let newz = floatPos.z + floatVel.z
        floatNode.position = SCNVector3(newx,newy,newz)
    }
    var floatPos:SCNVector3{get{return floatNode.position}}
    let floatNode:SCNNode
    var floatVel=SCNVector3(0,0,0)
    //var planeNode:SCNNode
    //anchorの位置にbaseNodeを移動のやり方。
    //add childNodeはどのタイミング->インスタンス生成時?
    var BaseNode=SCNNode()
    let scene : SCNScene// = SCNScene()
}






class Casting:GameScene{
    var campos=SCNVector3(0,0,0)
    var vel=SCNVector3(0,0,0)
    //func collision is needed
    //The Visualizer manages the velocity of the float
    //This class has to pass the initial posision and velocity of the float to the visualizer
    override func update(cameraNode: SCNNode, acc: SCNVector3, gyro: SCNVector3) {
        //*0.01が必要
        vel = acc
        campos = cameraNode.convertPosition(SCNVector3(0,0,0),to:nil)
    }
    
    func collision(){
        // return  the flag which means wheather collide or not
    }
    
    override func release(){
        visual.setInitialPos(to:campos)
        visual.setFloatVel(vel)
    }
    
    override func next() -> GameScene? {
        if isFinished() {
            return Hooking(status: status, visual: visual)
        }else {
            return nil
        }
    }
    func isFinished() -> Bool { return false }
}
/*
let cl = Hooking()
cl.FloatShinker()
*/
class Hooking:GameScene{
    //let visual=Vizualizer()
    override func update(cameraNode:SCNNode,acc:SCNVector3,gyro:SCNVector3){
        accHook = acc//using accHook.Z
        gryroHook = gyro//using gryroHook.X
    }
    
    var accHook = SCNVector3(0,0,0)
    var gryroHook = SCNVector3(0,0,0)
    var gyroX:Float = 0
    var accZ:Float = 0
    var seccount:Float = 0
    var WaitTime = Double.random(in: 1 ... 10)// ランダムな1から10を生成->待ち時間
    var calval:Float = 0
    var sendval:Int = 0
    
    //フッキングの判定と返す値を決定する関数
    func Hookingresult() {
        if (seccount > 16){
            /*
            intervalSeconds * 10 = 取得可能時間
            判定時間　1/60(位置の取得の更新)*30(カウンタ数) = 約0.5 秒
            */
            
            
            
            //計測の終了をGameManagerに通知(位置の取得{CMMotionManager}を終了させる。)
            //Gamestatusに処理の終了の通知
            
            
            accZ = abs(accZ)//accZは負の値なので計算しやすいように正の値に変換する。
            
            /*
            print("取得したgyroXの値は \(gyroX) です")
            print("取得したaccZの値は \(accZ) です")
            print("取得したsendvalの値は \(sendval) です")
            */
            
            //取得した値を掛け算する
            calval = gyroX * accZ
            
            switch calval {
                case 0..<10://1の判定
                    sendval = 1
                    break
                case 10..<130://2~7までの判定
                    calval = (calval+30)/20
                    sendval = Int(round(calval))
                    break
                case 130..<150://8~9の判定
                    calval = (calval-50)/10
                    sendval = Int(round(calval))
                    break
                case 150..<1000000://10の判定
                    sendval = 10
                    break
                default://0(動かしていない時)や、予期せぬ値
                    sendval = 0
                    break
            }
            //Gamestatusに値を引き渡す。(classの処理が全て終了)
            return status.HitCondition = sendval
            //print("判定終了 受け渡す値は\(sendval)です")
            
        }else{
            //画面上の動き(acc_z)が上向き(-Z方向),画面の回転(gyro_x)が手前側(+X方向)の時に値を取得する。
            if (gryroHook.x >= 0 && accHook.z <= 0){
                gyroX += gryroHook.x
                accZ += accHook.z
                seccount += 1
            } else if (gryroHook.x < 0 && accHook.z <= 0){
                //accZのみが正しい値の場合
                accZ += accHook.z
                seccount += 1
            } else if (gryroHook.x >= 0 && accHook.z > 0){
                //gyroXが正しい値の場合
                gyroX += gryroHook.x
                seccount += 1
            } else {
                //逆方向の判定が入った場合はカウンタの半分の値のみ追加する。
                seccount += 0.5
            }
        }
    }
    
    //ウキが沈む
    func FloatShinker(){
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + WaitTime) {
            //GameMnanagerにウキが沈んだことを伝える。(ウキが沈むというアクション)
            //Vizualizerにウキをどのくらい沈めたいかを通知
            //低音を流して振動で掛かったことを伝える。
            print("＋＋＋＋＋＋＋＋＋＋＋＋＋＋＋魚が掛かった＋＋＋＋＋＋＋＋＋＋＋＋＋＋＋＋")
            //ここで魚の情報が決定する。
            self.Hookingresult()
        }
    }
    
    override func next() -> GameScene? {
        if isFinished() {
            return Fight(status: status,visual: visual)//Fightに移行する。
        }else {
            return nil
        }
    }
    func isFinished() -> Bool { return false }
    
}

class Fight:GameScene{
    var campos=SCNVector3(0,0,0)
    var vel=SCNVector3(0,0,0)
    
    /*
    var gettime:Float=0
    var passtime:Float=0
    
    func tap(tapped: Bool) {
        // 適当に開始時点のDateを用意する
        let startDate = Date().addingTimeInterval(-180071.3325)
        // 開始からの経過秒数を取得する
        let timeInterval = Date().timeIntervalSince(startDate)
        let time = Float(timeInterval)
        passtime = time / 60
        if gettime > passtime{
            if tapped == true{
                let objPosition = visual.floatPos
                let dx = objPosition.x - campos.x / 10.0//移動距離
                let dz = objPosition.z - campos.z / 10.0
                // Visualizerにどういう形で返すか議論が必要
                let movePosition = SCNVector3(dx,0,dz)
                visual.moveFloat(to: movePosition)
            }
        }else{
            //tap時間終了のコード
        }
        
    }
    
    func timer(){
    }
    */
    
    override func tap() {
        let objPosition = visual.floatPos
        let dx = objPosition.x - campos.x / 10.0//移動距離
        let dz = objPosition.z - campos.z / 10.0
        // Visualizerにどういう形で返すか議論が必要
        let movePosition = SCNVector3(dx,0,dz)
        visual.moveFloat(to: movePosition)
    }
    
    override func update(cameraNode: SCNNode, acc: SCNVector3, gyro: SCNVector3) {
        vel = acc
        campos = cameraNode.convertPosition(SCNVector3(0,0,0),to:nil)
    }
    
    func isFinished() -> Bool { return false }
    /*
    処理が終了した場合、isFinished()にtrueを代入する。
    */
    
}
