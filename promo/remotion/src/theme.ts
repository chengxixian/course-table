/**
 * Design tokens extracted from the product source, not invented for the film.
 *
 * Sources:
 *  - lib/ui_theme.dart          -> Material 3 roles from seed #0B57D0, radii, font families
 *  - lib/ui/components.dart     -> CoursePalette._light (8 course colours), block metrics
 *  - lib/ui/motion.dart         -> 180/240/320ms, easeOutCubic, easeInOutCubicEmphasized
 *  - lib/ui/week_screen.dart    -> 88dp day column, 56dp period row, 4dp break
 */

export const C = {
  // lib/ui_theme.dart · ColorScheme.fromSeed(0xFF0B57D0, light)
  surface: "#FBF9FF",
  surfaceContainerLowest: "#FFFFFF",
  surfaceContainerLow: "#F5F2FA",
  surfaceContainer: "#EFEDF4",
  surfaceContainerHigh: "#E9E7EF",
  onSurface: "#1A1B20",
  onSurfaceVariant: "#45464F",
  outline: "#767680",
  outlineVariant: "#C6C5D0",
  primary: "#0B57D0",
  onPrimary: "#FFFFFF",
  primaryContainer: "#D8E2FF",
  onPrimaryContainer: "#001A41",
  secondaryContainer: "#D9E2F9",
  onSecondaryContainer: "#141B2C",
  error: "#BA1A1A",
  // week_screen.dart drag target highlight
  dropFill: "rgba(66,133,244,0.20)",
  dropStroke: "#4285F4",
} as const;

export type Course = {
  id: string;
  name: string;
  teacher: string;
  room: string;
  colorIndex: number;
  code: string;
  weeks: string;
  meets: {day: number; start: number; span: number}[];
};

/** lib/ui/components.dart · CoursePalette._light, verbatim. */
export const PALETTE = [
  {accent: "#006A60", container: "#C9F5ED", ink: "#003731"},
  {accent: "#3D5F90", container: "#D9E3F8", ink: "#0B2545"},
  {accent: "#6750A4", container: "#EADCFF", ink: "#21005D"},
  {accent: "#8B5000", container: "#FFDCC1", ink: "#2E1500"},
  {accent: "#3F6212", container: "#D9E7B8", ink: "#1A2E00"},
  {accent: "#8E3B55", container: "#FFD9E2", ink: "#3B0718"},
  {accent: "#455E91", container: "#DDE6FF", ink: "#102347"},
  {accent: "#745B00", container: "#FFE08A", ink: "#221B00"},
] as const;

export const FONT_CN = '"FandolFang", "Noto Serif CJK SC", serif';
export const FONT_LATIN = '"LiberationSerif", "Times New Roman", serif';

/** Flutter Curves, used as CSS easing strings. */
export const EASE = {
  enter: "cubic-bezier(0.215,0.61,0.355,1)", // easeOutCubic
  exit: "cubic-bezier(0.55,0.055,0.675,0.19)", // easeInCubic
  emphasized: "cubic-bezier(0.05,0.7,0.1,1)", // easeInOutCubicEmphasized
  standard: "cubic-bezier(0.2,0,0,1)",
} as const;

/** Frame counts at 30fps. */
export const T = {
  fast: 5.4, // 180ms
  medium: 7.2, // 240ms
  slow: 9.6, // 320ms
  popup: 12, // 400ms — components.dart anchored popup
  snap: 6, // 200ms — week_screen.dart drop snap
  shotIn: 24,
} as const;
