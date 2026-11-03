import type {Course} from "../theme";

/**
 * FICTIONAL demo data. No real student, no real personal data.
 * School names shown in the import ranking come from the app's public
 * assets/schools.json registry (public institutions, no personal data).
 */

export const PERIODS = [
  {i: 1, start: "08:00", end: "08:45"},
  {i: 2, start: "08:55", end: "09:40"},
  {i: 3, start: "10:00", end: "10:45"},
  {i: 4, start: "10:55", end: "11:40"},
  {i: 5, start: "14:00", end: "14:45"},
  {i: 6, start: "14:55", end: "15:40"},
  {i: 7, start: "16:00", end: "16:45"},
  {i: 8, start: "16:55", end: "17:40"},
  {i: 9, start: "19:00", end: "19:45"},
  {i: 10, start: "19:55", end: "20:40"},
  {i: 11, start: "20:50", end: "21:35"},
];

export const DAYS = ["一", "二", "三", "四", "五", "六", "日"];
export const DAY_DATES = [19, 20, 21, 22, 23, 24, 25];
export const TODAY_INDEX = 3; // 星期四 · 10月22日

export const SEMESTER = {
  weeks: 20,
  week: 8,
  range: "10月19日 – 10月25日",
  academicYear: "2026-2027",
  term: "第一学期",
};

export const COURSES: Course[] = [
  {
    id: "c1",
    name: "高等数学 A1",
    teacher: "陈景行",
    room: "文渊 1201",
    colorIndex: 0,
    code: "MA1012",
    weeks: "1-16",
    meets: [
      {day: 1, start: 1, span: 2},
      {day: 3, start: 3, span: 2},
    ],
  },
  {
    id: "c2",
    name: "机械制图 A",
    teacher: "褚明远",
    room: "文津 4508",
    colorIndex: 1,
    code: "ME1023",
    weeks: "1-16",
    meets: [
      {day: 2, start: 3, span: 2},
      {day: 4, start: 1, span: 2},
    ],
  },
  {
    id: "c3",
    name: "大学物理",
    teacher: "林知远",
    room: "明理 2102",
    colorIndex: 2,
    code: "PH1004",
    weeks: "1-16",
    meets: [{day: 1, start: 5, span: 2}],
  },
  {
    id: "c4",
    name: "数据结构",
    teacher: "苏映雪",
    room: "信息楼 302",
    colorIndex: 4,
    code: "CS2041",
    weeks: "1-12",
    meets: [
      {day: 2, start: 7, span: 2},
      {day: 4, start: 5, span: 2},
    ],
  },
  {
    id: "c5",
    name: "英语听说",
    teacher: "沈砚秋",
    room: "外语楼 205",
    colorIndex: 5,
    code: "EN1102",
    weeks: "1-16",
    meets: [
      {day: 3, start: 5, span: 2},
      {day: 5, start: 3, span: 2},
    ],
  },
  {
    id: "c6",
    name: "中国近现代史纲要",
    teacher: "罗一楠",
    room: "文澜 305",
    colorIndex: 7,
    code: "HI1002",
    weeks: "1-8",
    meets: [{day: 5, start: 1, span: 2}],
  },
  {
    id: "c7",
    name: "体育（篮球）",
    teacher: "韩川",
    room: "东区球场",
    colorIndex: 6,
    code: "PE1001",
    weeks: "1-16",
    meets: [{day: 5, start: 7, span: 2}],
  },
  {
    id: "c8",
    name: "机械工程导论",
    teacher: "葛小乐",
    room: "文渊 1105",
    colorIndex: 3,
    code: "ME1001",
    weeks: "1-8",
    meets: [{day: 4, start: 7, span: 2}],
  },
];

export const courseById = (id: string) => COURSES.find((c) => c.id === id)!;

export type Block = {
  course: Course;
  day: number;
  start: number;
  span: number;
  key: string;
};

/** Every block on the grid, ordered top-left -> bottom-right. */
export const BLOCKS: Block[] = COURSES.flatMap((course) =>
  course.meets.map((m) => ({
    course,
    day: m.day,
    start: m.start,
    span: m.span,
    key: `${course.id}-${m.day}-${m.start}`,
  })),
).sort((a, b) => a.day - b.day || a.start - b.start);

export const blockOf = (courseId: string, day: number, start: number) =>
  BLOCKS.find((b) => b.course.id === courseId && b.day === day && b.start === start)!;

export const timeRange = (start: number, span: number) => {
  const s = PERIODS[start - 1];
  const e = PERIODS[start - 1 + span - 1];
  return `${s.start}–${e.end}`;
};

/** Public rows of the app's 350-school registry (see assets/schools.json). */
export const SCHOOLS = [
  {name: "黄山学院", note: "校内统一身份认证 · 原生同步", badge: "原生"},
  {name: "铜陵学院", note: "社区提交 · 网页导入", badge: "网页"},
  {name: "安庆师范大学", note: "强智教务 · 网页导入", badge: "网页"},
];

export const IMPORT_SOURCES = [
  {tag: "WakeUp", label: "WakeUp 分享文件", note: "课程表导出的 JSON"},
  {tag: "ICS", label: "ICS 日历文件", note: "Apple / Google / Outlook"},
  {tag: "CSV", label: "CSV 表格", note: "逗号分隔的课表"},
  {tag: "XLSX", label: "Excel 表格", note: ".xlsx / .xls"},
  {tag: "PDF", label: "PDF 课表", note: "文本型 PDF"},
  {tag: "TXT", label: "纯文本", note: "网页或通知里复制"},
  {tag: "手动", label: "手动添加", note: "表单录入"},
];
