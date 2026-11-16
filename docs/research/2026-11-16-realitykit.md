# Research: realitykit (16/11/2026, Haiku 5.5 agent, read-only; verify items marked UNVERIFIED)

## RealityKit research report (iOS 18+, Swift 6, non-AR `RealityView`)

**Source caveat:** Apple's developer.apple.com pages returned only page titles to WebFetch, so most API facts come from the sosumi.ai mirror, which itself marks some signatures as inferred. Items marked UNVERIFIED need a check in Xcode 26 autocomplete or the live docs.

### 1. Procedural meshes (hoses, pipes)

- **Static geometry:** `MeshDescriptor(name:)` with `positions`, `normals`, `textureCoordinates` and `primitives = .triangles([...])`, then `MeshResource.generate(from:)`, which is `@MainActor` and `throws`. The page links to a `[MeshDescriptor]` overload, but its signature is UNVERIFIED. Sources: https://sosumi.ai/documentation/realitykit/meshdescriptor and https://sosumi.ai/documentation/realitykit/meshresource/generate(from:)
- **Dynamic geometry (whipping hoses, animated cables):** `LowLevelMesh` (iOS 18+, `@MainActor`, `Sendable`).
  - Setup: `LowLevelMesh.Descriptor` with `vertexCapacity`, `indexCapacity`, `vertexAttributes`, `vertexLayouts` and `indexType`. Then `try LowLevelMesh(descriptor:)`, then `parts` entries, then `MeshResource(from:)`.
  - Parts: WWDC24 shows `mesh.parts.append(LowLevelMesh.Part(indexOffset:indexCount:topology:materialIndex:bounds:))`. The sosumi page shows `parts.replaceAll`. Both may exist; UNVERIFIED which is current.
  - CPU updates: `withUnsafeMutableBytes(bufferIndex:)` and `withUnsafeMutableIndices`.
  - GPU updates: `replace(bufferIndex:using: MTLCommandBuffer)`.
  - Up to 4 vertex buffers, any Metal vertex format, 8 UV channels.
  - Sources: https://developer.apple.com/videos/play/wwdc2024/10104/ and https://sosumi.ai/documentation/realitykit/lowlevelmesh
- Reference sample: https://github.com/metal-by-example/metal-spatial-dynamic-mesh (60 Hz CPU and compute updates).
- Unofficial hitch report: building a new `MeshResource` from a `LowLevelMesh` synchronously cost 20–32 ms in a Unity-on-Vision-Pro thread, and reusing meshes avoided it. Source: https://discussions.unity.com/t/visionpro-framerate-hitch-every-time-spatial-mesh-updated/1556394 (secondary, visionOS).

**Recommendation:** Build each hose or pipe once with `MeshDescriptor` if its curve is static. If the curve moves, allocate a `LowLevelMesh` at max segment count up front and rewrite vertices in place. Never recreate the `MeshResource` per frame. Merge parts that share a material, which Apple recommends (https://developer.apple.com/videos/play/wwdc2023/10100/).

### 2. Per-frame transform updates (pistons, crank, valves)

- **ECS (Apple's recommended route):** conform to `System`, implement `init(scene:)` (required) and `update(context: SceneUpdateContext)`. Use a `static let` `EntityQuery(where: .has(X.self))` with `context.scene.performQuery(...)`. Components are structs, so write them back. Order systems with `static var dependencies: [SystemDependency]`. Register at app launch with `registerSystem()`. Sources: https://developer.apple.com/videos/play/wwdc2021/10074/ and https://sosumi.ai/documentation/realitykit/system
- **SceneEvents.Update:** an event fired once per frame, with `deltaTime`. Apple's own page returned only its title, so the subscribe signature is UNVERIFIED. Source: https://sosumi.ai/documentation/realitykit/sceneevents
- **Cost on A15:** Apple publishes no per-frame budgets. The guidance is qualitative: pre-create entities and toggle `isEnabled` rather than add and remove them, flatten hierarchies, lower update rates or the number of animated entities, and avoid bursts of updates that can bottleneck the render server (https://developer.apple.com/videos/play/wwdc2023/10100/). A forum reply says RealityKit does per-entity work every frame, so merging into chunks helps (anecdotal, https://developer.apple.com/forums/thread/746624 and the snippet search).

**Recommendation:** Run one `System` that reads the Swift simulation state and writes `Transform` for each moving part. Keep the moving part count small, and combine static parts into the mesh. Measure on device before scaling up.

### 3. Materials, IBL, shadows (non-AR)

- **`PhysicallyBasedMaterial`** (iOS 15+): `baseColor`, `roughness`, `metallic`, `clearcoat`, `emissiveColor`, `blending`. All RealityKit materials are tone-mapped by default; opt out with `UnlitMaterial(color:applyPostProcessToneMap:)`. Sources: https://sosumi.ai/documentation/realitykit/physicallybasedmaterial and https://developer.apple.com/videos/play/wwdc2023/10095/
- **Image-based lighting:** `ImageBasedLightComponent(source:intensityExponent:)` is iOS 18+. Pair it with `ImageBasedLightReceiverComponent(imageBasedLight:)`, and load `EnvironmentResource(named:)`. The WWDC23 example is visionOS-framed. The receiver's iOS availability is UNVERIFIED. Source: https://sosumi.ai/documentation/realitykit/imagebasedlightcomponent
- **Grounding shadows:** `GroundingShadowComponent(castsShadow:receivesShadow:fadeBehaviorNearPhysicalObjects:)`, iOS 18+. It is set per model entity, not per hierarchy, and no AR requirement is stated. One-sided 2D geometry only casts when its faces point at the receiver, so disable face culling or use watertight meshes. Source: https://sosumi.ai/documentation/realitykit/groundingshadowcomponent
- **Non-AR mode:** `RealityViewCameraContent.camera` (iOS 18+) with `.virtual`. The sosumi page lists `.virtual` and `.spatialTracking`, while a WWDC24 summary shows `.worldTracking` on iOS. The exact case list is UNVERIFIED. Source: https://sosumi.ai/documentation/realitykit/realityviewcameracontent/camera
- **Contradicted claim in the local skill:** `content.environment.lighting.resource` and `intensityExponent` (in `C:/Users/zboyd/.claude/skills/realitykit/references/realitykit-patterns.md`) do not match the sosumi `RealityViewEnvironment` page, which documents only `background` (`.default`, `.skybox`). Treat that snippet as unverified. Source: https://sosumi.ai/documentation/realitykit/realityviewenvironment
- **Shadow gap:** a forum question about non-AR ground shadows is unanswered in the snippet. Source: https://developer.apple.com/forums/thread/751211

### 4. Chase camera

- `PerspectiveCameraComponent` (fov, near, far), attached with `components.set(...)`. The camera looks down the entity's negative Z. In non-AR you must provide the camera yourself. Source: https://sosumi.ai/documentation/realitykit/perspectivecameracomponent
- Apple's docs say non-AR cameras are controlled by changing the `PerspectiveCamera` entity's transform.
- Orthographic projection is not supported (https://developer.apple.com/forums/thread/682731).
- A camera inside an anchor tree with `.spatialTracking` pinned content to the screen (https://developer.apple.com/forums/thread/762238 snippet). Keep the camera at scene root.
- No verified RealityView-specific follow-camera example exists. The approach: add the camera at scene root, then in a `System` (or `SceneEvents.Update`) smooth its transform toward the target offset, using `look(at:from:relativeTo:)` (exact `Entity` signature UNVERIFIED).

### 5. Large ground plane, grid, markers

- Apple provides no guidance for this. The recommended approach is one large plane (`MeshResource.generatePlane(width:depth:)`) with a tiled texture, or a `MeshDescriptor` plane with UVs scaled to the tile count. Tiling wrap mode and `PhysicallyBasedMaterial` texture transform are UNVERIFIED.
- Bake static markers and strip boards into one mesh with multiple parts, grouped by material. Do not create one entity per marker.

### 6. Performance on iPhone 13

- **Hardware (Apple):** A15 Bionic, 6-core CPU (2 performance, 4 efficiency), 4-core GPU. Source: https://support.apple.com/kb/SP851
- **Not on Apple's page (UNVERIFIED):** RAM (commonly cited as 4 GB) and display refresh rate (commonly 60 Hz).
- **OS support:** iOS 26 supports iPhone 11 and later, so iPhone 13 is supported. Source: https://www.macrumors.com/2025/06/09/ios-26-supports-iphone-11-and-newer/
- **No Apple frame-rate or entity budgets exist.** Anecdotal: non-AR RealityKit on iPhone 15 Pro was capped at 60 fps (https://developer.apple.com/forums/thread/746624). A third-party guide suggests under 100 entities is safe and 1000+ needs instancing (https://lobehub.com/skills/derklinke-codex-config-ios-realitykit, unofficial, treat as a rough rule only).
- **Tooling:** the RealityKit Trace template in Instruments (RealityKit Frames and Metrics instruments) and Reality Composer Pro scene statistics. Source: https://developer.apple.com/videos/play/wwdc2023/10100/
- **MeshInstancesComponent** was reported in the WWDC25 session 287 summary. That is likely iOS 26-only and would not run at the iOS 18 floor, but availability is UNVERIFIED. Source: https://developer.apple.com/videos/play/wwdc2025/287/

### 7. Physics: needed or not?

- An entity needs both `PhysicsBodyComponent` and `CollisionComponent` to take part in the simulation. Moving a physics entity needs `PhysicsMotionComponent`. Source: https://sosumi.ai/documentation/realitykit/physicsbodycomponent
- Kinematic bodies still collide. Driving a kinematic body with linear velocity passed through walls in one forum report, and switching modes during a drag caused jitter (https://developer.apple.com/forums/thread/814541 and https://developer.apple.com/forums/thread/762179).
- Apple's guidance favors static colliders over dynamic ones for cost (WWDC23 10100).

**Recommendation:** Pure-Swift vehicle physics that writes `Transform` each frame is the lower-risk route for a racing or drag game. Keep the sim in plain Swift structs and do collision against your own track and wall geometry. Use RealityKit `CollisionComponent` plus `InputTargetComponent` only for taps and picking. I found no Apple statement calling this the norm; it is a reasoned recommendation, not sourced.

### Risks

1. **No local profiling.** RealityKit Trace needs Instruments on a Mac, and the user has no local Mac. Performance can only be checked on CI artifacts or a borrowed Mac. Plan a device spike early.
2. **Unverified API details:** `[MeshDescriptor]` overload, `SceneEvents.Update` subscribe signature, `RealityViewCamera` case list, `ImageBasedLightReceiverComponent` on iOS, and the `parts` API form.
3. **Local skill inaccuracies:** `content.environment.lighting` and `.worldTracking` (see section 3). The skill also targets iOS 26 and Swift 6.3, not iOS 18.
4. **Frame-time unknowns on A15** have no Apple numbers. Set a measured budget in the spike rather than assuming one.

### Recommended approach (summary)

- Static hoses, pipes, track, markers: `MeshDescriptor` plus merged parts.
- Moving hoses or deforming parts: one pre-sized `LowLevelMesh`, CPU-written, never rebuilt per frame.
- Moving mechanics: one `System` that writes transforms from Swift sim state. Keep the moving part count small.
- Lighting: `DirectionalLight` or IBL via `ImageBasedLightComponent` (iOS 18+, verify receiver), `PhysicallyBasedMaterial`, `GroundingShadowComponent(castsShadow: true)` per model entity.
- Camera: `content.camera = .virtual`, `PerspectiveCameraComponent` at scene root, smoothed follow in a `System`.
- Physics: custom Swift vehicle sim, no RealityKit dynamics.
