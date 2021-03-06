//
//  OpenGLView.swift
//  HelloOpenGL_Swift
//
//  Created by DR on 8/24/15.
//  Copyright (c) 2015 DR. All rights reserved.
//
//  Based on code posted by Ray Wenderlich:
//  http://www.raywenderlich.com/3664/opengl-tutorial-for-ios-opengl-es-2-0
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit
import CoreMedia
import AVFoundation

struct Vertex {
    var Position: (Float, Float, Float)
    var Color: (Float, Float, Float, Float)
    var TexCoord: (Float, Float)
}

let TEX_COORD_MAX : Float = 4

class OpenGLView: UIView {
    var _context: EAGLContext?
    var _colorRenderBuffer = GLuint()
    var _colorSlot = GLuint()
    var _currentRotation = Float()
    var _depthRenderBuffer = GLuint()
    var _eaglLayer: CAEAGLLayer?
    var _modelViewUniform = GLuint()
    var _positionSlot = GLuint()
    var _projectionUniform = GLuint()
    
    // texture
    var _floorTexture = GLuint()
    var _fishTexture = GLuint()
    var _texCoordSlot = GLuint()
    var _textureUniform = GLuint()
    
    // buffers
    var _vertexBuffer = GLuint()
    var _indexBuffer = GLuint()
    var _vertexBuffer2 = GLuint()
    var _indexBuffer2 = GLuint()
    
    var _vertices = [
        // Front
        Vertex(Position: (1, -1, 0), Color: (1, 0, 0, 1), TexCoord: (TEX_COORD_MAX, 0)),
        Vertex(Position: (1, 1, 0), Color: (0, 1, 0, 1), TexCoord: (TEX_COORD_MAX, TEX_COORD_MAX)),
        Vertex(Position: (-1, 1, 0), Color: (0, 0, 1, 1), TexCoord: (0, TEX_COORD_MAX)),
        Vertex(Position: (-1, -1, 0), Color: (0, 0, 0, 1), TexCoord: (0, 0)),
        // Back
        Vertex(Position: (1, 1, -2), Color: (1, 0, 0, 1), TexCoord: (TEX_COORD_MAX, 0)),
        Vertex(Position: (-1, -1, -2), Color: (0, 1, 0, 1), TexCoord: (TEX_COORD_MAX, TEX_COORD_MAX)),
        Vertex(Position: (1, -1, -2), Color: (0, 0, 1, 1), TexCoord: (0, TEX_COORD_MAX)),
        Vertex(Position: (-1, 1, -2), Color: (0, 0, 0, 1), TexCoord: (0, 0)),
        // Left
        Vertex(Position: (-1, -1, 0), Color: (1, 0, 0, 1), TexCoord: (TEX_COORD_MAX, 0)),
        Vertex(Position: (-1, 1, 0), Color: (0, 1, 0, 1), TexCoord: (TEX_COORD_MAX, TEX_COORD_MAX)),
        Vertex(Position: (-1, 1, -2), Color: (0, 0, 1, 1), TexCoord: (0, TEX_COORD_MAX)),
        Vertex(Position: (-1, -1, -2), Color: (0, 0, 0, 1), TexCoord: (0, 0)),
        // Right
        Vertex(Position: (1, -1, -2), Color: (1, 0, 0, 1), TexCoord: (TEX_COORD_MAX, 0)),
        Vertex(Position: (1, 1, -2), Color: (0, 1, 0, 1), TexCoord: (TEX_COORD_MAX, TEX_COORD_MAX)),
        Vertex(Position: (1, 1, 0), Color: (0, 0, 1, 1), TexCoord: (0, TEX_COORD_MAX)),
        Vertex(Position: (1, -1, 0), Color: (0, 0, 0, 1), TexCoord: (0, 0)),
        // Top
        Vertex(Position: (1, 1, 0), Color: (1, 0, 0, 1), TexCoord: (TEX_COORD_MAX, 0)),
        Vertex(Position: (1, 1, -2), Color: (0, 1, 0, 1), TexCoord: (TEX_COORD_MAX, TEX_COORD_MAX)),
        Vertex(Position: (-1, 1, -2), Color: (0, 0, 1, 1), TexCoord: (0, TEX_COORD_MAX)),
        Vertex(Position: (-1, 1, 0), Color: (0, 0, 0, 1), TexCoord: (0, 0)),
        // Bottom
        Vertex(Position: (1, -1, -2), Color: (1, 0, 0, 1), TexCoord: (TEX_COORD_MAX, 0)),
        Vertex(Position: (1, -1, 0), Color: (0, 1, 0, 1), TexCoord: (TEX_COORD_MAX, TEX_COORD_MAX)),
        Vertex(Position: (-1, -1, 0), Color: (0, 0, 1, 1), TexCoord: (0, TEX_COORD_MAX)),
        Vertex(Position: (-1, -1, -2), Color: (0, 0, 0, 1), TexCoord: (0, 0)),
        ]
    
    var _indices : [GLubyte] = [
        // Front
        0, 1, 2,
        2, 3, 0,
        // Back
        4, 5, 6,
        4, 5, 7,
        // Left
        8, 9, 10,
        10, 11, 8,
        // Right
        12, 13, 14,
        14, 15, 12,
        // Top
        16, 17, 18,
        18, 19, 16,
        // Bottom
        20, 21, 22,
        22, 23, 20
    ]
    
    var _vertices2 = [
        Vertex(Position: (0.5, -0.5, 0.01), Color: (1, 1, 1, 1), TexCoord: (1, 1)),
        Vertex(Position: (0.5, 0.5, 0.01), Color: (1, 1, 1, 1), TexCoord: (1, 0)),
        Vertex(Position: (-0.5, 0.5, 0.01), Color: (1, 1, 1, 1), TexCoord: (0, 0)),
        Vertex(Position: (-0.5, -0.5, 0.01), Color: (1, 1, 1, 1), TexCoord: (0, 1)),
        ];
    
    var _indices2 : [GLubyte] = [
        1, 0, 2, 3
    ];
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if (self.setupLayer() != 0) {
            NSLog("OpenGLView init():  setupLayer() failed")
            return
        }
        if (self.setupContext() != 0) {
            NSLog("OpenGLView init():  setupContext() failed")
            return
        }
        if (self.setupDepthBuffer() != 0) {
            NSLog("OpenGLView init():  setupDepthBuffer() failed")
            return
        }
        if (self.setupRenderBuffer() != 0) {
            NSLog("OpenGLView init():  setupRenderBuffer() failed")
            return
        }
        if (self.setupFrameBuffer() != 0) {
            NSLog("OpenGLView init():  setupFrameBuffer() failed")
            return
        }
        if (self.compileShaders() != 0) {
            NSLog("OpenGLView init():  compileShaders() failed")
            return
        }
        if (self.setupVBOs() != 0) {
            NSLog("OpenGLView init():  setupVBOs() failed")
            return
        }
        if (self.setupDisplayLink() != 0) {
            NSLog("OpenGLView init():  setupDisplayLink() failed")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("OpenGLView init(coder:) has not been implemented")
    }
    
    override class func layerClass() -> AnyClass {
        return CAEAGLLayer.self
    }
    
    func compileShader(shaderName: String, shaderType: GLenum, shader: UnsafeMutablePointer<GLuint>) -> Int {
        let shaderPath = Bundle.main.pathForResource(shaderName, ofType:"glsl")
        var error : NSError?
        let shaderString: NSString?
        do {
            shaderString = try NSString(contentsOfFile: shaderPath!, encoding:String.Encoding.utf8.rawValue)
        } catch let error1 as NSError {
            error = error1
            shaderString = nil
        }
        if error != nil {
            NSLog("OpenGLView compileShader():  error loading shader: %@", error!.localizedDescription)
            return -1
        }
        
        shader.pointee = glCreateShader(shaderType)
        if (shader.pointee == 0) {
            NSLog("OpenGLView compileShader():  glCreateShader failed")
            return -1
        }
        var shaderStringUTF8 = shaderString!.utf8String
        var shaderStringLength: GLint = GLint(Int32(shaderString!.length))
        glShaderSource(shader.pointee, 1, &shaderStringUTF8, &shaderStringLength)
        
        glCompileShader(shader.pointee);
        var success = GLint()
        glGetShaderiv(shader.pointee, GLenum(GL_COMPILE_STATUS), &success)
        
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>(allocatingCapacity: 256)
            var infoLogLength = GLsizei()
            
            glGetShaderInfoLog(shader.pointee, GLsizei(sizeof(GLchar) * 256), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShader():  glCompileShader() failed:  %@", String(cString: infoLog))
            
            infoLog.deallocateCapacity(256)
            return -1
        }
        
        return 0
    }
    
    func compileShaders() -> Int {
        let vertexShader = UnsafeMutablePointer<GLuint>(allocatingCapacity: 1)
        if (self.compileShader(shaderName: "SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER), shader: vertexShader) != 0 ) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let fragmentShader = UnsafeMutablePointer<GLuint>(allocatingCapacity: 1)
        if (self.compileShader(shaderName: "SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER), shader: fragmentShader) != 0) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let program = glCreateProgram()
        glAttachShader(program, vertexShader.pointee)
        glAttachShader(program, fragmentShader.pointee)
        glLinkProgram(program)
        
        var success = GLint()
        
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &success)
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>(allocatingCapacity: 1024)
            var infoLogLength = GLsizei()
            
            glGetProgramInfoLog(program, GLsizei(sizeof(GLchar) * 1024), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShaders():  glLinkProgram() failed:  %@", String(cString:  infoLog))
            
            infoLog.deallocateCapacity(1024)
            fragmentShader.deallocateCapacity(1)
            vertexShader.deallocateCapacity(1)
            
            return -1
        }
        
        glUseProgram(program)
        
        _positionSlot = GLuint(glGetAttribLocation(program, "Position"))
        glEnableVertexAttribArray(_positionSlot)
        
        _colorSlot = GLuint(glGetAttribLocation(program, "SourceColor"))
        glEnableVertexAttribArray(_colorSlot)
        
        _texCoordSlot = GLuint(glGetAttribLocation(program, "TexCoordIn"));
        glEnableVertexAttribArray(_texCoordSlot);
        
        _textureUniform = GLuint(glGetUniformLocation(program, "Texture"));
        
        _floorTexture = self.setupTexture(fileName: "tile_floor.png");
        _fishTexture = self.setupTexture(fileName: "item_powerup_fish.png");
        
        _projectionUniform = GLuint(glGetUniformLocation(program, "Projection"))
        _modelViewUniform = GLuint(glGetUniformLocation(program, "Modelview"))
        
        fragmentShader.deallocateCapacity(1)
        vertexShader.deallocateCapacity(1)
        return 0
    }
    
    func render(displayLink: CADisplayLink) -> Int {
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA));
        glEnable(GLenum(GL_BLEND));
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_DEPTH_TEST))
        
        let projection = CC3GLMatrix.matrix()
        let h : CGFloat = 4.0 * self.frame.size.height / self.frame.size.width
        projection!.populate(fromFrustumLeft: GLfloat(-2), andRight: GLfloat(2), andBottom: GLfloat(-h/2), andTop: GLfloat(h/2), andNear: GLfloat(4), andFar: GLfloat(10))
        
        glUniformMatrix4fv(GLint(_projectionUniform), 1, 0, projection!.glMatrix)
        
        let modelView = CC3GLMatrix.matrix()
        modelView!.populate(fromTranslation: CC3VectorMake(GLfloat(sin(CACurrentMediaTime())), GLfloat(0), GLfloat(-7)))
        
        _currentRotation += Float(displayLink.duration) * Float(90)
        modelView!.rotate(by: CC3VectorMake(_currentRotation, _currentRotation, 0))
        
        glUniformMatrix4fv(GLint(_modelViewUniform), 1, 0, modelView!.glMatrix)
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height));
        
        
        // draw on first item
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vertexBuffer);
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), _indexBuffer);
        
        let positionSlotFirstComponent = UnsafePointer<Int>(bitPattern: 0)
        glEnableVertexAttribArray(_positionSlot)
        glVertexAttribPointer(_positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), positionSlotFirstComponent)
        
        glEnableVertexAttribArray(_colorSlot)
        let colorSlotFirstComponent = UnsafePointer<Int>(bitPattern: sizeof(Float) * 3)
        glVertexAttribPointer(_colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), colorSlotFirstComponent)
        
        let vertexSlotFirstComponent = UnsafePointer<Int>(bitPattern: sizeof(GLfloat) * 7)
        glVertexAttribPointer(_texCoordSlot, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(sizeof(Vertex)), vertexSlotFirstComponent);
        
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), _floorTexture);
        glUniform1i(GLint(_textureUniform), 0);
        
        
        let vertexBufferOffset = UnsafePointer<Void>(bitPattern: 0)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei((_indices.count * sizeof(GLubyte))/sizeof(GLubyte)),
                       GLenum(GL_UNSIGNED_BYTE), vertexBufferOffset)
        
        // draw on second item
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vertexBuffer2);
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), _indexBuffer2);
        
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), _fishTexture);
        glUniform1i(GLint(_textureUniform), 0);
        
        glUniformMatrix4fv(GLint(_modelViewUniform), 1, 0, modelView?.glMatrix);
        
        glVertexAttribPointer(_positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), positionSlotFirstComponent);
        glVertexAttribPointer(_colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), colorSlotFirstComponent);
        glVertexAttribPointer(_texCoordSlot, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), vertexSlotFirstComponent);
        
        glDrawElements(GLenum(GL_TRIANGLE_STRIP), GLsizei((_indices2.count * sizeof(GLubyte))/sizeof(GLubyte)), GLenum(GL_UNSIGNED_BYTE), positionSlotFirstComponent);
        
        
        _context!.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
        return 0
    }
    
    func setupContext() -> Int {
        let api : EAGLRenderingAPI = EAGLRenderingAPI.openGLES2
        _context = EAGLContext(api: api)
        
        if (_context == nil) {
            NSLog("Failed to initialize OpenGLES 2.0 context")
            return -1
        }
        if (!EAGLContext.setCurrent(_context)) {
            NSLog("Failed to set current OpenGL context")
            return -1
        }
        return 0
    }
    
    func setupDepthBuffer() -> Int {
        glGenRenderbuffers(1, &_depthRenderBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _depthRenderBuffer);
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
        return 0
    }
    
    func setupDisplayLink() -> Int {
        let displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(OpenGLView.render(displayLink:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode(rawValue: RunLoopMode.defaultRunLoopMode.rawValue))
        return 0
    }
    
    func setupFrameBuffer() -> Int {
        var framebuffer: GLuint = 0
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0),
                                  GLenum(GL_RENDERBUFFER), _colorRenderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), _depthRenderBuffer);
        return 0
    }
    
    func setupLayer() -> Int {
        _eaglLayer = self.layer as? CAEAGLLayer
        if (_eaglLayer == nil) {
            NSLog("setupLayer:  _eaglLayer is nil")
            return -1
        }
        _eaglLayer!.isOpaque = true
        return 0
    }
    
    func setupTexture(fileName: String) -> GLuint{
        let spriteImage: CGImage? = UIImage(named: fileName)?.cgImage
        if (spriteImage == nil) {
            print("Failed to load image!")
            exit(1)
        }
        let width: Int = spriteImage!.width
        let height: Int = spriteImage!.height
        let spriteData = UnsafeMutablePointer<GLubyte>(calloc(Int(UInt(CGFloat(width) * CGFloat(height) * 4)), sizeof(GLubyte)))
        
        let spriteContext: CGContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        spriteContext.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width) , height: CGFloat(height)), image: spriteImage!)
        var texName: GLuint = GLuint()
        glGenTextures(1, &texName)
        glBindTexture(GLenum(GL_TEXTURE_2D), texName)
        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), spriteData)
        
        free(spriteData)
        return texName
        
    }
    
    func setupRenderBuffer() -> Int {
        glGenRenderbuffers(1, &_colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _colorRenderBuffer)
        
        if (_context == nil) {
            NSLog("setupRenderBuffer():  _context is nil")
            return -1
        }
        if (_eaglLayer == nil) {
            NSLog("setupRenderBuffer():  _eagLayer is nil")
            return -1
        }
        if (_context!.renderbufferStorage(Int(GL_RENDERBUFFER), from: _eaglLayer!) == false) {
            NSLog("setupRenderBuffer():  renderbufferStorage() failed")
            return -1
        }
        return 0
    }
    
    func setupVBOs() -> Int {
        // first object
        glGenBuffers(1, &_vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (_vertices.count * sizeof(Vertex)), _vertices, GLenum(GL_STATIC_DRAW))
        
        glGenBuffers(1, &_indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), _indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (_indices.count * sizeof(GLubyte)), _indices, GLenum(GL_STATIC_DRAW))
        
        // second object
        glGenBuffers(1, &_vertexBuffer2)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vertexBuffer2)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (_vertices2.count * sizeof(Vertex)), _vertices2, GLenum(GL_STATIC_DRAW))
        
        glGenBuffers(1, &_indexBuffer2)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), _indexBuffer2)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (_indices2.count * sizeof(GLubyte)), _indices2, GLenum(GL_STATIC_DRAW))
        return 0
    }
    
}
