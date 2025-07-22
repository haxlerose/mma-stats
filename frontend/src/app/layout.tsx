import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { NavigationLayout } from "@/components/navigation";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "MMA Stats",
  description: "Comprehensive UFC data with round-by-round insights and fighter analytics",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <NavigationLayout>
          {children}
        </NavigationLayout>
      </body>
    </html>
  );
}
