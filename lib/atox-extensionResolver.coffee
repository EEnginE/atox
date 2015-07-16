FILE_TYPES =
  code: [
    'coffee', 'js', 'css', 'less', 'html'
    'h', 'c', 'hpp', 'cpp', 'h\\+\\+', 'c\\+\\+', 'hxx', 'cxx', 'cs', 'rs'
    'rb', 'pl', 'py', 'bat', 'sh', 'lua', 'php', 'ps1', 'vbs', 'tcl', 'el'
  ]
  media: [
    'png', 'jpg', 'jpeg', 'psb', 'xcf', 'tga', 'tiff', 'gif', 'bmp', 'dds', 'svg'
    'mp3', 'ogg', 'flac', 'iso', 'wav', 'mpeg', 'mpg', 'mpe', 'swf'
    'blend', 'gltf', 'obj', 'md3', 'md2', 'b3d', 'dae'
  ]
  binary: ['o', 'a', 'so', 'dll', 'exe', 'jar', 'deb', 'rpm']
  text: ['txt', 'md', 'odt', 'doc', 'log', 'tex', 'org']
  pdf: ['pdf', 'dvi']
  zip: ['cab', '7z', 'bzip2', 'bz2', 'gzip', 'lzip', 'lzma', 'rar', 'tar', 'gz', 'xz', 'zip']


module.exports =
class ExtensionResolver
  @resolve: (name) ->
    for i, j of FILE_TYPES
      for k in j
        match = name.match new RegExp "\.#{k}$", 'gi'
        unless match is null
          return i

    return 'text'
