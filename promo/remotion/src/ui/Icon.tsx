import React from "react";

/**
 * Line icons approximating the app's Pixelarticons set at small sizes.
 * Stroke width matches the 24dp pixel grid feel of lib/pixel_icons.dart.
 */
const PATHS: Record<string, string> = {
  chevron_left: "M15 4 L7 12 L15 20",
  chevron_right: "M9 4 L17 12 L9 20",
  arrow_back: "M20 12 H4 M11 5 L4 12 L11 19",
  sync: "M20 11 A8 8 0 0 0 6.2 6.2 L4 8.4 M4 4 v4.4 h4.4 M4 13 A8 8 0 0 0 17.8 17.8 L20 15.6 M20 20 v-4.4 h-4.4",
  calendar: "M4 6.5 h16 v13 h-16 z M4 10.5 h16 M8 3 v4 M16 3 v4",
  today: "M4 6.5 h16 v13 h-16 z M4 10.5 h16 M9 14 h2 v2 h-2 z",
  book: "M5 4 h10 a3 3 0 0 1 3 3 v13 h-10 a3 3 0 0 0 -3 3 z M5 4 v16",
  tune: "M4 7 h16 M4 12 h16 M4 17 h16 M9 5 v4 M15 10 v4 M8 15 v4",
  search: "M10.5 4 a6.5 6.5 0 1 1 0 13 a6.5 6.5 0 0 1 0 -13 z M15.5 15.5 L20 20",
  close: "M6 6 L18 18 M18 6 L6 18",
  clock: "M12 3.5 a8.5 8.5 0 1 1 0 17 a8.5 8.5 0 0 1 0 -17 z M12 7.5 v5 l3.2 2",
  check: "M4.5 12.5 L9.5 17.5 L19.5 6.5",
  share: "M12 3 v11 M8 7 l4 -4 4 4 M5 14 v5.5 h14 V14",
  event_ok: "M4 6.5 h16 v13 h-16 z M8 3 v4 M16 3 v4 M8.5 13.5 l2.5 2.5 4.5 -4.5",
  plus: "M12 5 v14 M5 12 h14",
  info: "M12 3.5 a8.5 8.5 0 1 1 0 17 a8.5 8.5 0 0 1 0 -17 z M12 10.5 v6 M12 7.5 v.6",
  drag: "M9 9 h2 v2 h-2 z M13 9 h2 v2 h-2 z M9 13 h2 v2 h-2 z M13 13 h2 v2 h-2 z",
};

export const Icon: React.FC<{
  name: keyof typeof PATHS | string;
  size?: number;
  color?: string;
  strokeWidth?: number;
  style?: React.CSSProperties;
}> = ({name, size = 20, color = "currentColor", strokeWidth = 1.9, style}) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    style={{display: "block", flex: "none", ...style}}
  >
    <path
      d={PATHS[name] ?? PATHS.info}
      stroke={color}
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);
