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

struct Vertex {
    var Position: (Float, Float, Float)
    var Color: (Float, Float, Float, Float)
}

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
    
    var _vertices = [
        Vertex(Position: ( 1, -1,  0), Color: (1, 0, 0, 1)),
        Vertex(Position: ( 1,  1,  0), Color: (1, 0, 0, 1)),
        Vertex(Position: (-1,  1,  0), Color: (0, 1, 0, 1)),
        Vertex(Position: (-1, -1,  0), Color: (0, 1, 0, 1)),
        Vertex(Position: ( 1, -1, -1), Color: (1, 0, 0, 1)),
        Vertex(Position: ( 1,  1, -1), Color: (1, 0, 0, 1)),
        Vertex(Position: (-1,  1, -1), Color: (0, 1, 0, 1)),
        Vertex(Position: (-1, -1, -1), Color: (0, 1, 0, 1))
    ]
    
    var _indices : [GLubyte] = [
        // Front
        0, 1, 2,
        2, 3, 0,
        // Back
        4, 6, 5,
        4, 7, 6,
        // Left
        2, 7, 3,
        7, 6, 2,
        // Right
        0, 4, 1,
        4, 1, 5,
        // Top
        6, 2, 1,
        1, 6, 5,
        // Bottom
        0, 3, 7,
        0, 7, 4
    ]
    
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
        let shaderPath = NSBundle.mainBundle().pathForResource(shaderName, ofType:"glsl")
        var error : NSError?
        let shaderString: NSString?
        do {
            shaderString = try NSString(contentsOfFile: shaderPath!, encoding:NSUTF8StringEncoding)
        } catch let error1 as NSError {
            error = error1
            shaderString = nil
        }
        if error != nil {
            NSLog("OpenGLView compileShader():  error loading shader: %@", error!.localizedDescription)
            return -1
        }
        
        shader.memory = glCreateShader(shaderType)
        if (shader.memory == 0) {
            NSLog("OpenGLView compileShader():  glCreateShader failed")
            return -1
        }
        var shaderStringUTF8 = shaderString!.UTF8String
        var shaderStringLength: GLint = GLint(Int32(shaderString!.length))
        glShaderSource(shader.memory, 1, &shaderStringUTF8, &shaderStringLength)
        
        glCompileShader(shader.memory);
        let success = UnsafeMutablePointer<GLint>.alloc(1)
        glGetShaderiv(shader.memory, GLenum(GL_COMPILE_STATUS), success)

        if (success != nil && success.memory == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.alloc(256)
            let infoLogLength = UnsafeMutablePointer<GLsizei>.alloc(1)
            
            glGetShaderInfoLog(shader.memory, GLsizei(sizeof(GLchar) * 256), infoLogLength, infoLog)
            NSLog("OpenGLView compileShader():  glCompileShader() failed:  %@", String.fromCString(infoLog)!)
            
            infoLog.destroy()
            infoLogLength.destroy()
            return -1
        }
        
        success.destroy()
        return 0
    }

    func compileShaders() -> Int {
        let vertexShader = UnsafeMutablePointer<GLuint>.alloc(1)
        if (self.compileShader("SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER), shader: vertexShader) != 0 ) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let fragmentShader = UnsafeMutablePointer<GLuint>.alloc(1)
        if (self.compileShader("SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER), shader: fragmentShader) != 0) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }

        let program = glCreateProgram()
        glAttachShader(program, vertexShader.memory)
        glAttachShader(program, fragmentShader.memory)
        glLinkProgram(program)

        let success = UnsafeMutablePointer<GLint>.alloc(1)
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), success)
        if (success != nil && success.memory == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.alloc(1024)
            let infoLogLength = UnsafeMutablePointer<GLsizei>.alloc(1)
            
            glGetProgramInfoLog(program, GLsizei(sizeof(GLchar) * 1024), infoLogLength, infoLog)
            NSLog("OpenGLView compileShaders():  glLinkProgram() failed:  %@", String.fromCString(infoLog)!)
            
            infoLog.destroy()
            infoLogLength.destroy()
            return -1
        }

        glUseProgram(program)

        _positionSlot = GLuint(glGetAttribLocation(program, "Position"))
        _colorSlot = GLuint(glGetAttribLocation(program, "SourceColor"))
        glEnableVertexAttribArray(_positionSlot)
        glEnableVertexAttribArray(_colorSlot)
        
        _projectionUniform = GLuint(glGetUniformLocation(program, "Projection"))
        _modelViewUniform = GLuint(glGetUniformLocation(program, "Modelview"))

        fragmentShader.destroy()
        vertexShader.destroy()
        success.destroy()
        return 0
    }
    
    func render(displayLink: CADisplayLink) -> Int {
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_DEPTH_TEST))
        
        let projection = CC3GLMatrix.matrix()
        let h : CGFloat = 4.0 * self.frame.size.height / self.frame.size.width
        projection.populateFromFrustumLeft(GLfloat(-2), andRight: GLfloat(2), andBottom: GLfloat(-h/2), andTop: GLfloat(h/2), andNear: GLfloat(4), andFar: GLfloat(10))
        glUniformMatrix4fv(GLint(_projectionUniform), 1, 0, projection.glMatrix)
        
        let modelView = CC3GLMatrix.matrix()
        modelView.populateFromTranslation(CC3VectorMake(GLfloat(sin(CACurrentMediaTime())), GLfloat(0), GLfloat(-7)))
        
        _currentRotation += Float(displayLink.duration) * Float(90)
        modelView.rotateBy(CC3VectorMake(_currentRotation, _currentRotation, 0))
        
        glUniformMatrix4fv(GLint(_modelViewUniform), 1, 0, modelView.glMatrix)
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height));
        
        let positionSlotFirstComponent = UnsafePointer<Int>(bitPattern:0)
        glEnableVertexAttribArray(_positionSlot)
        glVertexAttribPointer(_positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), positionSlotFirstComponent)
        
        glEnableVertexAttribArray(_colorSlot)
        let colorSlotFirstComponent = UnsafePointer<Int>(bitPattern:sizeof(Float) * 3)
        glVertexAttribPointer(_colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), colorSlotFirstComponent)

        let vertextBufferOffset = UnsafeMutablePointer<Void>(bitPattern: 0)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei((_indices.count * sizeof(GLubyte))/sizeof(GLubyte)),
             GLenum(GL_UNSIGNED_BYTE), vertextBufferOffset)
        
        _context!.presentRenderbuffer(Int(GL_RENDERBUFFER))
        return 0
    }
    
    func setupContext() -> Int {
        let api : EAGLRenderingAPI = EAGLRenderingAPI.OpenGLES2
        _context = EAGLContext(API: api)
        
        if (_context == nil) {
            NSLog("Failed to initialize OpenGLES 2.0 context")
            return -1
        }
        if (!EAGLContext.setCurrentContext(_context)) {
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
        let displayLink : CADisplayLink = CADisplayLink(target: self, selector: Selector("render:"))
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
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
        _eaglLayer!.opaque = true
        return 0
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
        if (_context!.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: _eaglLayer!) == false) {
            NSLog("setupRenderBuffer():  renderbufferStorage() failed")
            return -1
        }
        return 0
    }
    
    func setupVBOs() -> Int {
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (_vertices.count * sizeof(Vertex)), _vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer = GLuint()
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (_indices.count * sizeof(GLubyte)), _indices, GLenum(GL_STATIC_DRAW))
        return 0
    }
    
}