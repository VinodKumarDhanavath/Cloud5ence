import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
 title:"Cloud5ence | CX Consulting, CCaaS, AI & Salesforce Services",
 description:"Cloud5ence connects strategy, contact centers, cloud, AI, and Salesforce. Explore seven consulting services and client solutions, led by Vinod Dhanavath with 7+ years of hands-on CX and cloud experience.",
 icons:{icon:"/favicon.svg",shortcut:"/favicon.svg"},
};
export default function RootLayout({children}:Readonly<{children:React.ReactNode}>){return <html lang="en"><body>{children}</body></html>}
