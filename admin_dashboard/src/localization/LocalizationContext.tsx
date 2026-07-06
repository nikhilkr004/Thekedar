"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import { LocaleManager } from "./LocaleManager";
import en from "./locales/en.json";
import hi from "./locales/hi.json";

type Translations = typeof en;

const translationsMap: Record<string, Record<string, string>> = {
  en: en as unknown as Record<string, string>,
  hi: hi as unknown as Record<string, string>,
};

interface LocalizationContextProps {
  locale: string;
  setLocale: (locale: string) => Promise<void>;
  t: (key: keyof Translations | string) => string;
}

const LocalizationContext = createContext<LocalizationContextProps | undefined>(undefined);

export const LocalizationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [locale, setLocaleState] = useState<string>("en");

  useEffect(() => {
    const cached = LocaleManager.getCachedLocale();
    setLocaleState(cached);
  }, []);

  const changeLocale = async (newLocale: string) => {
    setLocaleState(newLocale);
    LocaleManager.cacheLocale(newLocale);
    try {
      await LocaleManager.syncLocaleToFirebase(newLocale);
    } catch (e) {
      console.error("Failed to sync locale to Firebase", e);
    }
  };

  const translate = (key: string): string => {
    const localeDict = translationsMap[locale] || translationsMap["en"];
    return localeDict[key] || key;
  };

  return (
    <LocalizationContext.Provider value={{ locale, setLocale: changeLocale, t: translate }}>
      {children}
    </LocalizationContext.Provider>
  );
};

export const useLocalization = () => {
  const context = useContext(LocalizationContext);
  if (!context) {
    throw new Error("useLocalization must be used within a LocalizationProvider");
  }
  return context;
};
