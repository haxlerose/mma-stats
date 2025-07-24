import React from "react";
import { cn } from "@/lib/utils";

interface SectionProps extends React.HTMLAttributes<HTMLElement> {
  children: React.ReactNode;
  spacing?: "sm" | "md" | "lg";
}

export function Section({
  spacing = "md",
  className,
  children,
  ...props
}: SectionProps) {
  const spacings = {
    sm: "py-6",
    md: "py-8", 
    lg: "py-12",
  };

  return (
    <section
      className={cn("w-full", spacings[spacing], className)}
      {...props}
    >
      {children}
    </section>
  );
}

export function SectionHeader({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("mb-6", className)} {...props}>
      {children}
    </div>
  );
}

export function SectionTitle({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h2 className={cn("text-2xl font-bold text-gray-900", className)} {...props}>
      {children}
    </h2>
  );
}

export function SectionSubtitle({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p className={cn("text-gray-700 mt-2", className)} {...props}>
      {children}
    </p>
  );
}