###
# Copyright (C) 2012 jareiko / http://www.jareiko.net/
###

array_geometry = exports? and @ or @array_geometry = {}

class array_geometry.ArrayGeometry extends THREE.BufferGeometry
  constructor: ->
    super()
    @vertexIndexArray = []
    @vertexPositionArray = []
    @vertexNormalArray = []
    @vertexUvArray = []  # Supports only one channel of UVs.
    @vertexColorArray = []
    @offsets = []

  updateOffsets: ->
    if @vertexPositionArray.length > 65535
      console.log 'WARNING: ArrayGeometry too big!'
      console.log @
    @offsets[0] =
      start: 0
      count: @vertexIndexArray.length
      offset: 0

  addGeometry: (geom) ->
    pts = [ 'a', 'b', 'c', 'd' ]
    offsetPosition = @vertexPositionArray.length

    for v in geom.vertices
      @vertexPositionArray.push v.x, v.y, v.z

    for face, faceIndex in geom.faces
      if face.d?
        @vertexIndexArray.push face.a, face.b, face.d
        @vertexIndexArray.push face.b, face.c, face.d
      else
        @vertexIndexArray.push face.a, face.b, face.c

      for norm, pt in face.vertexNormals
        @vertexNormalArray[face[pts[pt]] * 3 + 0] = norm.x
        @vertexNormalArray[face[pts[pt]] * 3 + 1] = norm.y
        @vertexNormalArray[face[pts[pt]] * 3 + 2] = norm.z

      # Not sure if colors works this way.
      #@vertexColorArray[f[pts[i]] * 3] = n for n, i in f.colors

      # We support only one channel of UVs.
      uvs = geom.faceVertexUvs[0][faceIndex]
      for uv, pt in uvs
        @vertexUvArray[face[pts[pt]] * 2 + 0] = uv.u
        @vertexUvArray[face[pts[pt]] * 2 + 1] = uv.v

    @updateOffsets()
    return

  mergeMesh: (mesh) ->
    vertexOffset = @vertexPositionArray.length / 3
    geom2 = mesh.geometry
    tmpVec3 = new THREE.Vector3

    if mesh.matrixAutoUpdate then mesh.updateMatrix()

    matrix = mesh.matrix
    matrixRotation = new THREE.Matrix4()
    matrixRotation.extractRotation matrix, mesh.scale

    # Copy vertex data.
    i = 0
    posns = geom2.vertexPositionArray
    norms = geom2.vertexNormalArray
    hasNorms = norms? and norms.length == posns.length
    while i < posns.length
      tmpVec3.set posns[i + 0], posns[i + 1], posns[i + 2]
      matrix.multiplyVector3 tmpVec3
      @vertexPositionArray.push tmpVec3.x, tmpVec3.y, tmpVec3.z
      if hasNorms
        tmpVec3.set norms[i + 0], norms[i + 1], norms[i + 2]
        matrixRotation.multiplyVector3 tmpVec3
        @vertexNormalArray.push tmpVec3.x, tmpVec3.y, tmpVec3.z
      i += 3
    @vertexUvArray = @vertexUvArray.concat geom2.vertexUvArray
    @vertexColorArray = @vertexColorArray.concat geom2.vertexColorArray

    # Copy indices.
    for idx in geom2.vertexIndexArray
      @vertexIndexArray.push idx + vertexOffset

    @updateOffsets()
    return

  computeBoundingSphere: -> @computeBounds()
  computeBoundingBox: -> @computeBounds()
  computeBounds: ->
    bb =
      min: new THREE.Vector3(Infinity, Infinity, Infinity)
      max: new THREE.Vector3(-Infinity, -Infinity, -Infinity)
    maxRadius = 0
    i = 0
    posns = @vertexPositionArray
    numVerts = posns.length
    while i < numVerts
      x = posns[i + 0]
      y = posns[i + 1]
      z = posns[i + 2]
      bb.min.x = Math.min bb.min.x, x
      bb.max.x = Math.max bb.max.x, x
      bb.min.y = Math.min bb.min.y, y
      bb.max.y = Math.max bb.max.y, y
      bb.min.z = Math.min bb.min.z, z
      bb.max.z = Math.max bb.max.z, z
      radius = Math.sqrt x * x + y * y + z * z
      maxRadius = Math.max maxRadius, radius
      i += 3

    @boundingBox = bb
    @boundingSphere =
      radius: maxRadius
    return

  createBuffers: (gl) ->
    # Indices.
    @vertexIndexBuffer = gl.createBuffer()
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @vertexIndexBuffer
    gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(@vertexIndexArray), gl.STATIC_DRAW
    @vertexIndexBuffer.itemSize = 1
    @vertexIndexBuffer.numItems = @vertexIndexArray.length

    # Positions.
    @vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertexPositionBuffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array(@vertexPositionArray), gl.STATIC_DRAW
    @vertexPositionBuffer.itemSize = 3
    @vertexPositionBuffer.numItems = @vertexPositionArray.length

    # Normals.
    if @vertexNormalArray? and @vertexNormalArray.length > 0
      @vertexNormalBuffer = gl.createBuffer()
      gl.bindBuffer gl.ARRAY_BUFFER, @vertexNormalBuffer
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array(@vertexNormalArray), gl.STATIC_DRAW
      @vertexNormalBuffer.itemSize = 3
      @vertexNormalBuffer.numItems = @vertexNormalArray.length

    # UVs.
    if @vertexUvArray? and @vertexUvArray.length > 0
      @vertexUvBuffer = gl.createBuffer()
      gl.bindBuffer gl.ARRAY_BUFFER, @vertexUvBuffer
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array(@vertexUvArray), gl.STATIC_DRAW
      @vertexUvBuffer.itemSize = 2
      @vertexUvBuffer.numItems = @vertexUvArray.length

    # Colors.
    if @vertexColorArray? and @vertexColorArray.length > 0
      @vertexColorBuffer = gl.createBuffer()
      gl.bindBuffer gl.ARRAY_BUFFER, @vertexColorBuffer
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array(@vertexColorArray), gl.STATIC_DRAW
      @vertexColorBuffer.itemSize = 4
      @vertexColorBuffer.numItems = @vertexColorArray.length

    return

