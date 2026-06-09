import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import QueryProvider from '@/components/shared/QueryProvider';
import LayoutWrapper from '@/components/shared/LayoutWrapper';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Thekedar Connect | Control Dashboard',
  description: 'Web Control Panel and Content Management System for Thekedar Connect.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body className={`${inter.className} min-h-full text-slate-900 bg-slate-50 antialiased`}>
        <QueryProvider>
          <LayoutWrapper>
            {children}
          </LayoutWrapper>
        </QueryProvider>
      </body>
    </html>
  );
}
