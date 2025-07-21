/**
 * Utility functions for the MMA Stats application
 */

import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Utility for merging Tailwind classes
 * Combines clsx and tailwind-merge for optimal class handling
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Format a date string for display
 */
export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long", 
    day: "numeric",
  });
}

/**
 * Format fighting time (e.g., "3:45" -> "3:45 of Round 2")
 */
export function formatFightTime(time: string, round: number): string {
  return `${time} of Round ${round}`;
}

/**
 * Calculate striking accuracy percentage
 */
export function calculateAccuracy(landed: number, attempted: number): number {
  if (attempted === 0) return 0;
  return Math.round((landed / attempted) * 100);
}

/**
 * Format control time from seconds to mm:ss
 */
export function formatControlTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`;
}

/**
 * Convert height from inches to feet and inches display
 */
export function formatHeight(heightInInches: number | null): string {
  if (!heightInInches) return "N/A";
  
  const feet = Math.floor(heightInInches / 12);
  const inches = heightInInches % 12;
  return `${feet}'${inches}"`;
}

/**
 * Format reach in inches with units
 */
export function formatReach(reachInInches: number | null): string {
  if (!reachInInches) return "N/A";
  return `${reachInInches}"`;
}