import React from "react";
import { cn } from "@/lib/utils";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "outline";
  size?: "sm" | "md" | "lg";
  children: React.ReactNode;
}

export function Button({
  variant = "primary",
  size = "md",
  className,
  children,
  ...props
}: ButtonProps) {
  const baseStyles = [
    "inline-flex items-center justify-center rounded-lg font-medium",
    "transition-colors duration-200",
    "focus:outline-none focus:ring-2 focus:ring-offset-2",
    "disabled:opacity-50 disabled:cursor-not-allowed",
  ];

  const variants = {
    primary: [
      "bg-primary text-white hover:bg-red-700",
      "focus:ring-primary",
    ],
    secondary: [
      "bg-secondary text-white hover:bg-blue-700",
      "focus:ring-secondary", 
    ],
    outline: [
      "border border-border bg-background text-foreground",
      "hover:bg-card focus:ring-border",
    ],
  };

  const sizes = {
    sm: "px-3 py-1.5 text-sm",
    md: "px-4 py-2 text-base", 
    lg: "px-6 py-3 text-lg",
  };

  return (
    <button
      className={cn(
        baseStyles,
        variants[variant],
        sizes[size],
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
}