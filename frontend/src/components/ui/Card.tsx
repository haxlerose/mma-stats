import React from "react";
import { cn } from "@/lib/utils";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  variant?: "default" | "hover";
  padding?: "sm" | "md" | "lg";
}

export function Card({
  variant = "default",
  padding = "md",
  className,
  children,
  ...props
}: CardProps) {
  const baseStyles = [
    "bg-card border border-border rounded-lg",
    "shadow-sm",
  ];

  const variants = {
    default: "",
    hover: [
      "transition-all duration-200 cursor-pointer",
      "hover:shadow-md hover:scale-[1.02]",
      "active:scale-[0.98]",
    ],
  };

  const paddings = {
    sm: "p-3",
    md: "p-4",
    lg: "p-6",
  };

  return (
    <div
      className={cn(
        baseStyles,
        variants[variant],
        paddings[padding],
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

// Sub-components for semantic structure
export function CardHeader({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("mb-3", className)} {...props}>
      {children}
    </div>
  );
}

export function CardTitle({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3 className={cn("font-bold text-lg text-foreground", className)} {...props}>
      {children}
    </h3>
  );
}

export function CardContent({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("text-muted space-y-2", className)} {...props}>
      {children}
    </div>
  );
}