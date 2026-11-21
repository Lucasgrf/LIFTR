enum PhotoPose {
  front('front', 'Frente'),
  back('back', 'Costas'),
  sideLeft('side_left', 'Lado Esq.'),
  sideRight('side_right', 'Lado Dir.'),
  other('other', 'Outro');

  const PhotoPose(this.code, this.label);

  final String code;
  final String label;

  static PhotoPose fromCode(String? code) {
    switch (code) {
      case 'front':
        return PhotoPose.front;
      case 'back':
        return PhotoPose.back;
      case 'side_left':
        return PhotoPose.sideLeft;
      case 'side_right':
        return PhotoPose.sideRight;
      default:
        return PhotoPose.other;
    }
  }
}
