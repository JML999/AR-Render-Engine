import Foundation
import MetalKit

class ShaderManager {
    let device: MTLDevice
    let library: MTLLibrary
    
    public init(device: MTLDevice){
        self.device = device
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            fatalError("Default library not found in app bundle! Aborted.")
        }
        library = defaultLibrary
    }
    
    var cachedFullScreenQuadPipelineState: MTLRenderPipelineState!
    
    public func fullScreenQuadPipelineState(pass: MTLRenderPassDescriptor)->MTLRenderPipelineState{
        
        if let quadPipelineState = cachedFullScreenQuadPipelineState {
            return quadPipelineState
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "videoQuadVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "videoQuadFragment")
        descriptor.colorAttachments[0].pixelFormat = pass.colorAttachments[0].texture?.pixelFormat ?? .invalid
        descriptor.depthAttachmentPixelFormat = pass.depthAttachment.texture?.pixelFormat ?? .invalid
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        
        descriptor.vertexDescriptor = vertexDescriptor
        
        do{
            cachedFullScreenQuadPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            return cachedFullScreenQuadPipelineState!
        } catch {
            fatalError("Failed to load render pipeline state for full screen quad")
        }
    }
    
    var cachedGeometryPipelineState: MTLRenderPipelineState?
    
    func pipelineState(for geometry: Geometry, pass: MTLRenderPassDescriptor) -> MTLRenderPipelineState {
        if let cachedPipeline = cachedGeometryPipelineState {
            return cachedPipeline
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "blinnPhongVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "blinnPhongFragment")
        
        descriptor.colorAttachments[0].pixelFormat = pass.colorAttachments[0].texture?.pixelFormat ?? .invalid
        descriptor.colorAttachments[0].isBlendingEnabled = true
        
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        descriptor.depthAttachmentPixelFormat = pass.depthAttachment.texture?.pixelFormat ?? .invalid
        
        descriptor.vertexDescriptor = geometry.vertexDescriptor
        
        do {
            cachedGeometryPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            return cachedGeometryPipelineState!
            
        } catch {
            fatalError("Unable to create Geometry Render pipeline state")
        }
    }
}
