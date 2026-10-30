class SchoolPreset {
  final String name;
  final String loginUrl;
  final bool adapted;
  final bool native;
  final String note;
  const SchoolPreset({required this.name, required this.loginUrl, this.adapted = true, this.native = false, this.note = ''});
}

const List<SchoolPreset> kSchoolPresets = [
  SchoolPreset(name: '黄山学院', loginUrl: 'https://mwx.hsu.edu.cn/zhxy/home', adapted: true, native: true, note: '校内统一身份认证 · 原生同步'),
];
