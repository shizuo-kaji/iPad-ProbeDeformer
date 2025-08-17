/**
 * @file ViewController.swift
 * @brief the main view class for the probedeformer
 * @section LICENSE
 *                   the MIT License
 * @section Requirements:   Eigen 3, DCN library
 * @version 0.20
 * @date  Oct. 2017
 * @author Shizuo KAJI
 */

import UIKit
import GLKit
import OpenGLES
import Foundation
import AVFoundation
import CoreVideo
import CoreFoundation

private let PROBEIMAGE = "arrow"
private let VDIV: Int32 = 100
private let HDIV: Int32 = 100
private let EPSILON: Float = 1e-8
private let ANICOM = false

class ViewController: GLKViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, FileViewControllerDelegate {
    
    // MARK: - Properties
    
    // mesh data
    var mainImage: ImageVertices!
    
    // is the camera on?
    var cameraMode = false
    
    // index of current image
    var imageIdx = 0
    
    // currently manipulated probe
    var selectedProbe: Probe?
    var selectedProbePair: Probe?
    var undoProbe: Probe?
    var undoX: GLfloat = 0
    var undoY: GLfloat = 0
    var undoTheta: GLfloat = 0
    var undoRadius: GLfloat = 0
    
    // probe texture
    var probeTexture: GLKTextureInfo!
    
    // screen size
    var ratioHeight: Float = 0
    var ratioWidth: Float = 0
    var screen = CGSize.zero
    
    // for capturing
    var captureDevice: AVCaptureDevice?
    var deviceInput: AVCaptureDeviceInput?
    var session: AVCaptureSession?
    var videoOutput: AVCaptureVideoDataOutput?
    var textureCache: CVOpenGLESTextureCache?
    var textureObject: CVOpenGLESTexture?
    var cameraTextureName: GLuint = 0
    
    // MARK: - IBOutlets
    @IBOutlet weak var cameraSw: UISegmentedControl!
    @IBOutlet weak var prbSizeSl: UISlider!
    
    // MARK: - Properties from parent class
    var context: EAGLContext!
    var effect: GLKBaseEffect!
    var fileViewController: FileViewController!
    
    // MARK: - Class Methods
    
    class var images: [String] {
        if ANICOM {
            return ["Dog.png", "Cat.png", "Bulldog.png", "Chihuahua.png", "Pomeranian.png",
                    "Cat1.png", "Cat2.png", "Cat3.png", "Cat4.png",
                    "Meerkat.png", "Pomeranian.png", "Rabbit.png", "Toypoodle.png"]
        } else {
            return ["Default.png"]
        }
    }
    
    // MARK: - Load and Unload
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // File Dialog
        fileViewController = FileViewController()
        addChild(fileViewController)
        fileViewController.didMove(toParent: self)
        fileViewController.delegate = self
        
        // OpenGL
        context = EAGLContext(api: .openGLES2)
        if context == nil {
            print("Failed to create ES context")
        }
        
        let glkView = view as! GLKView
        glkView.context = context
        EAGLContext.setCurrent(context)
        glkView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        
        // default parameter
        cameraMode = false
        undoProbe = nil
        selectedProbe = nil
        imageIdx = 0
        
        // gestures
        createGestureRecognizers()
        
        // load default image
        mainImage = ImageVertices(vDiv: GLuint(VDIV), hDiv: GLuint(HDIV))
        mainImage.load(UIImage(named: ViewController.images[imageIdx])!)
        
        guard let path = Bundle.main.path(forResource: PROBEIMAGE, ofType: "png") else {
            print("Could not find probe image")
            return
        }
        
        let options = [GLKTextureLoaderOriginBottomLeft: NSNumber(value: true)]
        do {
            probeTexture = try GLKTextureLoader.texture(withContentsOfFile: path, options: options)
        } catch {
            print("Error loading texture from image: \\(error)")
        }
        
        setupGL()
        
        mainImage.symmetric = false
        mainImage.fixRadius = true
    }
    
    deinit {
        // Clean up camera resources
        if let textureObject = textureObject {
            self.textureObject = nil
        }
        
        if let textureCache = textureCache {
            CVOpenGLESTextureCacheFlush(textureCache, 0)
            self.textureCache = nil
        }
        
        tearDownGL()
        if EAGLContext.current() == context {
            EAGLContext.setCurrent(nil)
        }
    }
    
    // viewDidUnload is deprecated in iOS 6+, functionality moved to viewDidDisappear and deinit
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // In modern iOS, the system handles memory warnings automatically
        // Only perform essential cleanup here
    }
    
    // MARK: - OpenGL
    
    func setupGL() {
        EAGLContext.setCurrent(context)
        effect = GLKBaseEffect()
        setupScreen()
    }
    
    func setupScreen() {
        let glHeight: Float
        let glWidth: Float
        let ratio: Float
        
        screen.height = UIScreen.main.bounds.size.height
        screen.width = UIScreen.main.bounds.size.width
        ratio = Float(screen.height / screen.width)
        
        if Float(screen.width) * mainImage.image_height < Float(screen.height) * mainImage.image_width {
            glWidth = mainImage.image_width
            glHeight = glWidth * ratio
        } else {
            glHeight = mainImage.image_height
            glWidth = glHeight / ratio
        }
        
        ratioHeight = glHeight / Float(screen.height)
        ratioWidth = glWidth / Float(screen.width)
        
        let projectionMatrix = GLKMatrix4MakeOrtho(-glWidth/2.0, glWidth/2.0, -glHeight/2.0, glHeight/2.0, -1, 1)
        effect.transform.projectionMatrix = projectionMatrix
    }
    
    func tearDownGL() {
        var name = mainImage.texture.name
        glDeleteTextures(1, &name)
        glDeleteTextures(1, &cameraTextureName)
        name = probeTexture.name
        glDeleteTextures(1, &name)
        EAGLContext.setCurrent(context)
        effect = nil
    }
    
    // MARK: - GLKView and GLKViewController delegate methods
    
    // GLKViewController's update method is deprecated and not needed in modern iOS
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glEnable(GLenum(GL_BLEND))
        effect.prepareToDraw()
        
        renderImage()
        if mainImage.showPrb && mainImage.prbSizeMultiplier > 0.25 {
            renderProbe(mainImage.probes)
        }
    }
    
    // Render image
    func renderImage() {
        if cameraMode {
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), cameraTextureName)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_GENERATE_MIPMAP_HINT), GL_TRUE)
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        } else {
            effect.texture2d0.name = mainImage.texture.name
            effect.texture2d0.enabled = GLboolean(GL_TRUE)
            effect.prepareToDraw()
        }
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Float>.size * 2), mainImage.verticesArr)
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Float>.size * 2), mainImage.textureCoordsArr)
        
        for i in 0..<mainImage.verticalDivisions {
            glDrawArrays(GLenum(GL_TRIANGLE_STRIP), GLint(i * (mainImage.horizontalDivisions * 2 + 2)), GLsizei(mainImage.horizontalDivisions * 2 + 2))
        }
    }
    
    // Render probe
    func renderProbe(_ probes: NSMutableArray) {
        effect.texture2d0.name = probeTexture.name
        effect.texture2d0.enabled = GLboolean(GL_TRUE)
        effect.prepareToDraw()
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        
        for probe in probes {
            let probe = probe as! Probe
            glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Float>.size * 2), probe.getVertices())
            glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Float>.size * 2), probe.getTextureCoords())
            glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        }
    }
    
    // MARK: - Touch event tracking
    
    func createGestureRecognizers() {
        let singleFingerDoubleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleDoubleTap(_:)))
        singleFingerDoubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(singleFingerDoubleTap)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
        rotateGesture.delegate = self
        view.addGestureRecognizer(rotateGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    // Simultaneous Gesture Recognition
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // prevent view's gesture recognition from stealing from toolbar
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
    
    // Double tap
    @objc func handleSingleDoubleTap(_ sender: UITapGestureRecognizer) {
        var p = sender.location(in: view)
        p.x = (p.x - screen.width/2.0) * CGFloat(ratioWidth)
        p.y = (screen.height/2.0 - p.y) * CGFloat(ratioHeight)
        
        mainImage.freezeProbes()
        
        undoProbe = nil
        let clickRadius = Float(mainImage.probeRadius * mainImage.probeRadius * mainImage.prbSizeMultiplier * 5)
        for probe in mainImage.probes {
            let probe = probe as! Probe
            if probe.distance2X(Float(p.x), y: Float(p.y)) < clickRadius {
                undoProbe = probe
                mainImage.probes.remove(probe)
                break
            }
        }
        
        if undoProbe == nil {
            mainImage.makeNewProbe(with: p)
            if mainImage.symmetric && abs(Float(p.x)) > mainImage.probeRadius {
                p.x = -p.x
                mainImage.makeNewProbe(with: p)
            }
        }
    }
    
    // find which probe is touched and select it
    func gestureBegan(_ p: CGPoint) {
        selectedProbe = nil
        selectedProbePair = nil
        let clickRadius = Float(mainImage.probeRadius * mainImage.probeRadius * mainImage.prbSizeMultiplier * 3)
        
        for probe in mainImage.probes {
            let probe = probe as! Probe
            if probe.distance2X(Float(p.x), y: Float(p.y)) < clickRadius {
                selectedProbe = probe
                undoX = probe.x
                undoY = probe.y
                undoTheta = probe.theta
                undoRadius = probe.radius
                
                if mainImage.symmetric {
                    for probePair in mainImage.probes {
                        let probePair = probePair as! Probe
                        if probePair.distance2X(-probe.x, y: probe.y) < EPSILON && selectedProbe !== probePair {
                            selectedProbePair = probePair
                            break
                        }
                    }
                }
                break
            }
        }
    }
    
    // Pan
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            var p = sender.location(in: view)
            p.x = (p.x - screen.width/2.0) * CGFloat(ratioWidth)
            p.y = (screen.height/2.0 - p.y) * CGFloat(ratioHeight)
            gestureBegan(p)
            
        case .changed:
            var dp = sender.translation(in: view)
            sender.setTranslation(.zero, in: view)
            dp.x *= CGFloat(ratioWidth)
            dp.y *= CGFloat(ratioHeight)
            
            if let selectedProbe = selectedProbe {
                selectedProbe.setPosDx(Float(dp.x), dy: Float(-dp.y), dtheta: 0.0)
                selectedProbePair?.setPosDx(Float(-dp.x), dy: Float(-dp.y), dtheta: 0.0)
            } else if !ANICOM {
                for probe in mainImage.probes {
                    let probe = probe as! Probe
                    probe.setPosDx(Float(dp.x), dy: Float(-dp.y), dtheta: 0.0)
                }
            }
            mainImage.deform()
            
        case .ended:
            undoProbe = selectedProbe
            
        default:
            break
        }
    }
    
    // Rotation
    @objc func handleRotateGesture(_ sender: UIRotationGestureRecognizer) {
        if mainImage.dm == MLS_RIGID || mainImage.dm == MLS_SIM { return }
        
        switch sender.state {
        case .began:
            var p = sender.location(in: view)
            p.x = (p.x - screen.width/2.0) * CGFloat(ratioWidth)
            p.y = (screen.height/2.0 - p.y) * CGFloat(ratioHeight)
            gestureBegan(p)
            
        case .changed:
            if let selectedProbe = selectedProbe {
                let dtheta = Float(sender.rotation)
                sender.rotation = 0
                selectedProbe.setPosDx(0.0, dy: 0.0, dtheta: -dtheta)
                selectedProbePair?.setPosDx(0.0, dy: 0.0, dtheta: dtheta)
            }
            mainImage.deform()
            
        case .ended:
            undoProbe = selectedProbe
            
        default:
            break
        }
    }
    
    // Pinch
    @objc func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            var p = sender.location(in: view)
            p.x = (p.x - screen.width/2.0) * CGFloat(ratioWidth)
            p.y = (screen.height/2.0 - p.y) * CGFloat(ratioHeight)
            gestureBegan(p)
            
        case .changed:
            let scale = Float(sender.scale)
            sender.scale = 1
            
            if !mainImage.fixRadius {
                if let selectedProbe = selectedProbe {
                    selectedProbe.radius = max(selectedProbe.radius * scale, 0.1)
                    selectedProbe.computeOrigVertex()
                    if let selectedProbePair = selectedProbePair {
                        selectedProbePair.radius = max(selectedProbe.radius * scale, 0.1)
                        selectedProbePair.computeOrigVertex()
                    }
                } else {
                    for probe in mainImage.probes {
                        let probe = probe as! Probe
                        probe.radius = max(probe.radius * scale, 0.1)
                        probe.computeOrigVertex()
                    }
                }
                mainImage.deform()
            }
            
        case .ended:
            undoProbe = selectedProbe
            
        default:
            break
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func pushButton_Initialize(_ sender: UIBarButtonItem) {
        print("Initialize")
        mainImage.initOrigVertices()
        mainImage.probes.removeAllObjects()
        mainImage.deform()
    }
    
    @IBAction func pushRemoveAllProbes(_ sender: UIBarButtonItem) {
        mainImage.freezeProbes()
        mainImage.probes.removeAllObjects()
    }
    
    @IBAction func pushUndo(_ sender: UIBarButtonItem) {
        if undoProbe == nil && mainImage.probes.count > 0 {
            mainImage.probes.removeLastObject()
        } else if let undoProbe = undoProbe, mainImage.probes.contains(undoProbe) {
            undoProbe.x = undoX
            undoProbe.y = undoY
            undoProbe.theta = undoTheta
            undoProbe.radius = undoRadius
            undoProbe.setPosDx(0.0, dy: 0.0, dtheta: 0.0)
            if let selectedProbePair = selectedProbePair {
                selectedProbePair.x = -undoX
                selectedProbePair.y = undoY
                selectedProbePair.theta = -undoTheta
                selectedProbePair.radius = undoRadius
                selectedProbePair.setPosDx(0.0, dy: 0.0, dtheta: 0.0)
            }
        } else if let undoProbe = undoProbe {
            mainImage.probes.add(undoProbe)
        }
        print("Undo")
        mainImage.deform()
    }
    
    @IBAction func pushDeformMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mainImage.dm = DCNBlend
        case 1:
            mainImage.dm = LinearBlend
        case 2:
            mainImage.dm = MLS_RIGID
        case 3:
            mainImage.dm = MLS_SIM
        default:
            break
        }
        print("deform mode: \\(mainImage.dm.rawValue)")
        mainImage.deform()
    }
    
    @IBAction func pushWeightMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mainImage.wm = EUCLIDEAN
            mainImage.euclideanWeighting()
        case 1:
            mainImage.wm = HARMONIC
            mainImage.harmonicWeighting()
        case 2:
            mainImage.wm = BIHARMONIC
            mainImage.harmonicWeighting()
        default:
            break
        }
        mainImage.deform()
    }
    
    @IBAction func pushSaveImg(_ sender: UIBarButtonItem) {
        print("saving image")
        let image = (view as! GLKView).snapshot
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(savingImageIsFinished(_:didFinishSavingWithError:contextInfo:)), nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let dir = paths.first!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stTime = formatter.string(from: Date())
        let csvfile = "\\(stTime).csv"
        let pth = (dir as NSString).appendingPathComponent(csvfile)
        print(pth)
        
        let mstr = NSMutableString()
        mstr.append("#vertices x,y\\n")
        for i in 0..<mainImage.numVertices {
            mstr.append("\\(mainImage.vertices[2*i]),\\(mainImage.vertices[2*i+1])\\n")
        }
        mstr.append("#probes ix,iy,itheta,x,y,theta,radius\\n")
        for probe in mainImage.probes {
            let probe = probe as! Probe
            let str = "\\(probe.ix),\\(probe.iy),\\(probe.itheta),\\(probe.x),\\(probe.y),\\(probe.theta),\\(probe.radius)\\n"
            mstr.append(str)
        }
        mstr.append("#closest vertex to each probe\\n")
        for probe in mainImage.probes {
            let probe = probe as! Probe
            let i = probe.closestPt
            mstr.append("\\(i),\\(mainImage.vertices[2*i]),\\(mainImage.vertices[2*i+1])\\n")
        }
        
        let outData = mstr.data(using: String.Encoding.utf8.rawValue)!
        do {
            try outData.write(to: URL(fileURLWithPath: pth))
            print("csv saved")
        } catch {
            print("csv save failed: \(error)")
        }
    }
    
    @objc func savingImageIsFinished(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
        let title: String
        let msg: String
        
        if let error = error {
            title = "error"
            msg = "Save failed."
        } else {
            title = "Saved"
            msg = "Image saved in Camera Roll"
        }
        
        let ac = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            print("OK button tapped.")
        }
        ac.addAction(okAction)
        present(ac, animated: true, completion: nil)
    }
    
    // Load new image
    @IBAction func pushButton_ReadImage(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        } else {
            print("Photo library not available")
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        stopCamera()
        var name = mainImage.texture.name
        glDeleteTextures(1, &name)
        let pImage = info[.originalImage] as! UIImage
        mainImage.load(pImage)
        setupScreen()
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // help screen
    @IBAction func unwindToFirstScene(_ unwindSegue: UIStoryboardSegue) {
        // Unwind segue implementation
    }
    
    // Device orientation change - updated for modern iOS
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            if self.cameraMode {
                self.cameraOrientation()
            }
            self.setupScreen()
        }, completion: nil)
    }
    
    // MARK: - Camera Methods
    
    @IBAction func pushCameraSw(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            stopCamera()
            mainImage.load(UIImage(named: ViewController.images[imageIdx])!)
            print("Camera OFF")
        case 1:
            do {
                try initializeCamera()
                cameraOrientation()
                print("Camera ON")
            } catch {
                print("camera init error : \\(error)")
                cameraSw.selectedSegmentIndex = 0
            }
        default:
            break
        }
        setupScreen()
    }
    
    func initializeCamera() throws {
        cameraMode = true
        captureDevice = nil
        
        // Updated camera discovery for modern iOS
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        captureDevice = discoverySession.devices.first
        
        guard let captureDevice = captureDevice else {
            throw NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVCaptureDevicePositionBack not found"])
        }
        
        deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        
        session = AVCaptureSession()
        session?.beginConfiguration()
        session?.sessionPreset = .hd1280x720
        session?.addInput(deviceInput!)
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        session?.addOutput(videoOutput!)
        
        session?.commitConfiguration()
        session?.startRunning()
        
        for connection in videoOutput?.connections ?? [] {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        // Clean up any existing texture cache
        if textureCache != nil {
            textureCache = nil
        }
        
        let cacheAttributes: [String: Any] = [:]
        let cvError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, cacheAttributes as CFDictionary, context, nil, &textureCache)
        if cvError != kCVReturnSuccess {
            throw NSError(domain: "Camera", code: Int(cvError), userInfo: [NSLocalizedDescriptionKey: "CVOpenGLESTextureCacheCreate failed with error: \(cvError)"])
        }
    }
    
    func stopCamera() {
        cameraMode = false
        cameraSw.selectedSegmentIndex = 0
        
        // Clean up texture resources
        if let textureObject = textureObject {
            self.textureObject = nil
        }
        
        if let textureCache = textureCache {
            CVOpenGLESTextureCacheFlush(textureCache, 0)
            self.textureCache = nil
        }
        
        DispatchQueue.global(qos: .default).async {
            if let session = self.session, session.isRunning {
                session.stopRunning()
                if let deviceInput = self.deviceInput {
                    session.removeInput(deviceInput)
                }
                if let videoOutput = self.videoOutput {
                    session.removeOutput(videoOutput)
                }
                self.session = nil
                self.videoOutput = nil
                self.deviceInput = nil
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer")
            return
        }
        
        let bufferWidth = CVPixelBufferGetWidth(imageBuffer)
        let bufferHeight = CVPixelBufferGetHeight(imageBuffer)
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        // Clean up previous texture object before creating new one
        if let textureObject = textureObject {
            self.textureObject = nil
        }
        
        var esTexture: CVOpenGLESTexture?
        let textureAttributes: [String: Any] = [:]
        let cvError = CVOpenGLESTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache!,
            imageBuffer,
            textureAttributes as CFDictionary,
            GLenum(GL_TEXTURE_2D),
            GL_RGBA,
            GLsizei(bufferWidth),
            GLsizei(bufferHeight),
            GLenum(GL_BGRA),
            GLenum(GL_UNSIGNED_BYTE),
            0,
            &esTexture
        )
        
        if cvError != kCVReturnSuccess {
            print("CVOpenGLESTextureCacheCreateTextureFromImage failed with error: \(cvError)")
            return
        }
        
        guard let esTexture = esTexture else {
            print("Failed to create OpenGL ES texture")
            return
        }
        
        // Update texture name and cache
        cameraTextureName = CVOpenGLESTextureGetName(esTexture)
        textureObject = esTexture
        
        // Flush the texture cache to ensure proper memory management
        CVOpenGLESTextureCacheFlush(textureCache!, 0)
    }
    
    func cameraOrientation() {
        let orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .unknown:
            orientation = .portrait
            mainImage.image_width = 720
            mainImage.image_height = 1280
        case .portrait:
            orientation = .portrait
            mainImage.image_width = 720
            mainImage.image_height = 1280
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
            mainImage.image_width = 720
            mainImage.image_height = 1280
        case .landscapeLeft:
            orientation = .landscapeRight
            mainImage.image_width = 1280
            mainImage.image_height = 720
        case .landscapeRight:
            orientation = .landscapeLeft
            mainImage.image_width = 1280
            mainImage.image_height = 720
        case .faceUp, .faceDown:
            orientation = .portrait
            mainImage.image_width = 720
            mainImage.image_height = 1280
        @unknown default:
            orientation = .portrait
            mainImage.image_width = 720
            mainImage.image_height = 1280
        }
        
        for connection in videoOutput?.connections ?? [] {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
        }
        
        setupScreen()
        mainImage.initOrigVertices()
        mainImage.deform()
    }
    
    // MARK: - Additional Actions
    
    @IBAction func loadCSV(_ sender: Any) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let filename = (paths[0] as NSString).appendingPathComponent(fileViewController.selectedPath)
        
        do {
            let csv = try String(contentsOfFile: filename, encoding: .utf8)
            mainImage.probes.removeAllObjects()
            
            let scanner = Scanner(string: csv)
            let chSet = CharacterSet.newlines
            var readingMode = 0
            var i = 0
            
            while !scanner.isAtEnd {
                guard let line = scanner.scanUpToCharacters(from: chSet) else { continue }
                
                if line.hasPrefix("#vertices") {
                    readingMode = 1
                    print("loading vertices..")
                    continue
                } else if line.hasPrefix("#probes") {
                    readingMode = 2
                    continue
                } else if line.hasPrefix("#") {
                    break
                }
                
                let array = line.components(separatedBy: ",")
                _ = scanner.scanCharacters(from: chSet)
                
                switch readingMode {
                case 1:
                    mainImage.vertices[2*i] = Float(array[0]) ?? 0
                    mainImage.vertices[2*i+1] = Float(array[1]) ?? 0
                    i += 1
                case 2:
                    let p = CGPoint(x: CGFloat(Float(array[0]) ?? 0), y: CGFloat(Float(array[1]) ?? 0))
                    let newprobe = mainImage.makeNewProbe(with: p)
                    newprobe!.itheta = Float(array[2]) ?? 0
                    newprobe!.radius = Float(array[6]) ?? 0
                    newprobe!.computeOrigVertex()
                    newprobe!.setPosX(Float(array[3]) ?? 0, y: Float(array[4]) ?? 0, theta: Float(array[5]) ?? 0)
                default:
                    break
                }
            }
            
            print("finish loading: \\(filename)")
            undoProbe = nil
            selectedProbe = nil
            mainImage.freezeProbes()
        } catch {
            return
        }
    }
    
    @IBAction func pushPickFile(_ sender: Any) {
        view.addSubview(fileViewController.view)
        let center = fileViewController.contentView.center
        let view = fileViewController.contentView!
        
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        view.center = center
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            view.transform = .identity
            view.center = center
        }, completion: nil)
        fileViewController.loadPaths()
    }
    
    @IBAction func pushCycleImg(_ sender: Any) {
        stopCamera()
        var name = mainImage.texture.name
        glDeleteTextures(1, &name)
        let imgs = ViewController.images
        imageIdx = imageIdx == imgs.count - 1 ? 0 : imageIdx + 1
        mainImage.load(UIImage(named: ViewController.images[imageIdx])!)
        setupScreen()
    }
    
    @IBAction func pushSymMode(_ sender: UISegmentedControl) {
        mainImage.symmetric = (sender.selectedSegmentIndex == 0)
        mainImage.deform()
    }
    
    @IBAction func pushRadFix(_ sender: UISegmentedControl) {
        mainImage.fixRadius = (sender.selectedSegmentIndex == 0)
    }
    
    @IBAction func prbSizeSliderChanged(_ sender: Any) {
        mainImage.prbSizeMultiplier = prbSizeSl.value
        for probe in mainImage.probes {
            let probe = probe as! Probe
            probe.szMultiplier = mainImage.prbSizeMultiplier
            probe.computeOrigVertex()
        }
    }
    
    @IBAction func pushShowPrb(_ sender: UIBarButtonItem) {
        if mainImage.showPrb {
            sender.title = "Show"
            mainImage.showPrb = false
        } else {
            sender.title = "Hide"
            mainImage.showPrb = true
        }
        print("show probe: \\(mainImage.showPrb)")
    }
}
