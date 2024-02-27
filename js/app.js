import {
  MSDFTextGeometry,
  MSDFTextMaterial,
  uniforms,
} from "three-msdf-text-utils"
import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import gui from "lil-gui"
import gsap from "gsap"

import fragment from "./shader/fragment.glsl"
import vertex from "./shader/vertex.glsl"
import textFragment from "./shader/textFragment.glsl"
import textVertex from "./shader/textVertex.glsl"

import font from "../assets/Inter-SemiBold-msdf.json"
import fontPng from "../assets/Inter-SemiBold.png"

export default class Sketch {
  constructor(options) {
    this.scene = new THREE.Scene()

    this.container = options.dom
    this.width = this.container.offsetWidth
    this.height = this.container.offsetHeight
    this.renderer = new THREE.WebGLRenderer()
    this.renderer.setPixelRatio(window.devicePixelRatio)
    this.renderer.setSize(this.width, this.height)
    this.renderer.setClearColor(0x111111, 1)
    this.renderer.outputColorSpace = THREE.SRGBColorSpace

    this.container.appendChild(this.renderer.domElement)

    this.camera = new THREE.PerspectiveCamera(
      70,
      window.innerWidth / window.innerHeight,
      0.01,
      100
    )

    // var frustumSize = 10;
    // var aspect = window.innerWidth / window.innerHeight;
    // this.camera = new THREE.OrthographicCamera( frustumSize * aspect / - 2, frustumSize * aspect / 2, frustumSize / 2, frustumSize / - 2, -1000, 1000 );
    this.camera.position.set(0, 0, 2)
    this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.time = 0

    this.isPlaying = true

    this.addObjects()
    this.resize()
    this.render()
    this.setupResize()
    this.settings()
  }

  settings() {
    let that = this
    this.settings = {
      progress: 0,
      progress2: 0,
      progress3: 0,
      progress4: 0,
      go: () => {
        const timeline = gsap.timeline({
          defaults: {
            ease: "expo.out",
          },
          onComplete: (self) => {
            // reset animation
            this.textMaterial.uniforms.uProgress.value = 0
            this.textMaterial.uniforms.uProgress2.value = 0
            this.textMaterial.uniforms.uProgress3.value = 0
            this.textMaterial.uniforms.uProgress4.value = 0
          },
        })

        timeline.to(
          [
            this.textMaterial.uniforms.uProgress,
            this.textMaterial.uniforms.uProgress2,
            this.textMaterial.uniforms.uProgress3,
            this.textMaterial.uniforms.uProgress4,
          ],
          {
            value: 1,
            duration: 3.5,
            stagger: 0.25,
          }
        )
      },
    }
    this.gui = new gui()
    this.gui.add(this.settings, "progress", 0, 1, 0.01).onChange((value) => {
      this.textMaterial.uniforms.uProgress.value = value
    })

    this.gui.add(this.settings, "progress2", 0, 1, 0.01).onChange((value) => {
      this.textMaterial.uniforms.uProgress2.value = value
    })
    this.gui.add(this.settings, "progress3", 0, 1, 0.01).onChange((value) => {
      this.textMaterial.uniforms.uProgress3.value = value
    })
    this.gui.add(this.settings, "progress4", 0, 1, 0.01).onChange((value) => {
      this.textMaterial.uniforms.uProgress4.value = value
    })

    this.gui.add(this.settings, "go")
  }

  setupResize() {
    window.addEventListener("resize", this.resize.bind(this))
  }

  resize() {
    this.width = this.container.offsetWidth
    this.height = this.container.offsetHeight
    this.renderer.setSize(this.width, this.height)
    this.camera.aspect = this.width / this.height
    this.camera.updateProjectionMatrix()
  }

  addObjects() {
    // this.material = new THREE.ShaderMaterial({
    //   extensions: {
    //     derivatives: "#extension GL_OES_standard_derivatives : enable",
    //   },
    //   side: THREE.DoubleSide,
    //   uniforms: {
    //     time: { type: "f", value: 0 },
    //     resolution: { type: "v4", value: new THREE.Vector4() },
    //     progress: { value: 0 },
    //   },
    //   // wireframe: true,
    //   // transparent: true,
    //   vertexShader: vertex,
    //   fragmentShader: fragment,
    // })

    // this.geometry = new THREE.PlaneGeometry(1, 1, 1, 1)

    // this.plane = new THREE.Mesh(this.geometry, this.material)
    // this.scene.add(this.plane)

    Promise.all([loadFontAtlas(fontPng)]).then(([atlas]) => {
      const geometry = new MSDFTextGeometry({
        text: "HELLO",
        font: font,
      })

      this.textMaterial = new THREE.ShaderMaterial({
        side: THREE.DoubleSide,
        transparent: true,
        defines: {
          IS_SMALL: false,
        },
        extensions: {
          derivatives: true,
        },
        uniforms: {
          // Common
          ...uniforms.common,

          // Rendering
          ...uniforms.rendering,

          // Strokes
          ...uniforms.strokes,

          // color
          ...{
            uStrokeColor: { value: new THREE.Color(0x00ff00) },
            uProgress: { value: 0 },
            uProgress2: { value: 0 },
            uProgress3: { value: 0 },
            uProgress4: { value: 0 },
            time: { value: 0 },
          },
        },
        vertexShader: textVertex,
        fragmentShader: textFragment,
      })

      this.textMaterial.uniforms.uMap.value = atlas
      const mesh = new THREE.Mesh(geometry, this.textMaterial)

      this.scene.add(mesh)
      mesh.scale.set(0.02, -0.02, 0.02)
      mesh.position.x = -1.35
    })
    function loadFontAtlas(path) {
      const promise = new Promise((resolve, reject) => {
        const loader = new THREE.TextureLoader()
        loader.load(path, resolve)
      })
      return promise
    }
  }

  stop() {
    this.isPlaying = false
  }

  play() {
    if (!this.isPlaying) {
      this.render()
      this.isPlaying = true
    }
  }

  render() {
    if (!this.isPlaying) return
    this.time += 0.05

    requestAnimationFrame(this.render.bind(this))
    this.renderer.render(this.scene, this.camera)
  }
}

new Sketch({
  dom: document.getElementById("container"),
})
