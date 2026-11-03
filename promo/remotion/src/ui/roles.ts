import React from "react";
import {C} from "../theme";
import {mixHex} from "../lib/anim";

/** Material 3 surface roles the film can retint (shot 7 路 dynamic colour). */
export type Roles = {
  surface: string;
  surfaceContainerLowest: string;
  surfaceContainerLow: string;
  surfaceContainer: string;
  surfaceContainerHigh: string;
  onSurface: string;
  onSurfaceVariant: string;
  outlineVariant: string;
  primary: string;
  onPrimary: string;
  primaryContainer: string;
  onPrimaryContainer: string;
  secondaryContainer: string;
  onSecondaryContainer: string;
};

export const DEFAULT_ROLES: Roles = {
  surface: C.surface,
  surfaceContainerLowest: C.surfaceContainerLowest,
  surfaceContainerLow: C.surfaceContainerLow,
  surfaceContainer: C.surfaceContainer,
  surfaceContainerHigh: C.surfaceContainerHigh,
  onSurface: C.onSurface,
  onSurfaceVariant: C.onSurfaceVariant,
  outlineVariant: C.outlineVariant,
  primary: C.primary,
  onPrimary: C.onPrimary,
  primaryContainer: C.primaryContainer,
  onPrimaryContainer: C.onPrimaryContainer,
  secondaryContainer: C.secondaryContainer,
  onSecondaryContainer: C.onSecondaryContainer,
};

/**
 * Additional palettes the app offers (lib/ui_theme.dart palettes/paletteSeeds),
 * expanded to the surface roles that a real dynamic-colour scheme would move.
 */
export const PALETTE_ROLES: Record<string, Roles> = {
  blue: DEFAULT_ROLES,
  teal: {
    surface: "#F5FBF8",
    surfaceContainerLowest: "#FFFFFF",
    surfaceContainerLow: "#EBF5F0",
    surfaceContainer: "#E4F0EA",
    surfaceContainerHigh: "#DDEAE4",
    onSurface: "#101B17",
    onSurfaceVariant: "#3F4A45",
    outlineVariant: "#B8C9C2",
    primary: "#00696B",
    onPrimary: "#FFFFFF",
    primaryContainer: "#9CF1F2",
    onPrimaryContainer: "#002021",
    secondaryContainer: "#CDE8E0",
    onSecondaryContainer: "#08201B",
  },
  rose: {
    surface: "#FFF8F8",
    surfaceContainerLowest: "#FFFFFF",
    surfaceContainerLow: "#FBEEF0",
    surfaceContainer: "#F7E7EA",
    surfaceContainerHigh: "#F1DEE2",
    onSurface: "#201A1B",
    onSurfaceVariant: "#524346",
    outlineVariant: "#D5C2C5",
    primary: "#B3266A",
    onPrimary: "#FFFFFF",
    primaryContainer: "#FFD9E4",
    onPrimaryContainer: "#3E001D",
    secondaryContainer: "#FBD9E3",
    onSecondaryContainer: "#2B151C",
  },
};

export const ThemeCtx = React.createContext<Roles>(DEFAULT_ROLES);
export const useRoles = () => React.useContext(ThemeCtx);

/** Blend two full role sets (used by the dynamic-colour shot). */
export const mixRoles = (a: Roles, b: Roles, t: number): Roles => {
  const out = {} as Roles;
  (Object.keys(a) as (keyof Roles)[]).forEach((k) => {
    out[k] = mixHex(a[k], b[k], t);
  });
  return out;
};

/**
 * Dynamic-colour morph with per-role latency: the surface washes first, the
 * containers follow, the primary ink lands last — reads like ink diffusing.
 */
export const mixRolesStaggered = (a: Roles, b: Roles, t: number): Roles => {
  const clamp01 = (v: number) => Math.max(0, Math.min(1, v));
  const ts = clamp01(t / 0.74);
  const tc = clamp01((t - 0.12) / 0.74);
  const tp = clamp01((t - 0.26) / 0.74);
  const SURF: (keyof Roles)[] = [
    "surface",
    "surfaceContainerLowest",
    "surfaceContainerLow",
    "surfaceContainer",
    "surfaceContainerHigh",
    "outlineVariant",
    "onSurfaceVariant",
  ];
  const PRIM: (keyof Roles)[] = [
    "primary",
    "onPrimary",
    "primaryContainer",
    "onPrimaryContainer",
    "secondaryContainer",
    "onSecondaryContainer",
  ];
  const out = {} as Roles;
  (Object.keys(a) as (keyof Roles)[]).forEach((k) => {
    const tt = SURF.includes(k) ? ts : PRIM.includes(k) ? tp : tc;
    out[k] = mixHex(a[k], b[k], tt);
  });
  return out;
};