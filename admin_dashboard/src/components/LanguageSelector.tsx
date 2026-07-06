"use client";

import React from "react";
import { useLocalization } from "../localization/LocalizationContext";

export const LanguageSelector: React.FC = () => {
  const { locale, setLocale, t } = useLocalization();

  const handleLanguageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setLocale(e.target.value);
  };

  return (
    <div className="flex items-center gap-2 p-2 border border-slate-700 bg-slate-900 rounded-lg max-w-xs shadow-md">
      <label htmlFor="language-select" className="text-sm font-semibold text-slate-300">
        {t("changeLanguage")}:
      </label>
      <select
        id="language-select"
        value={locale}
        onChange={handleLanguageChange}
        className="bg-slate-800 text-white text-sm rounded-md p-1 outline-none border border-slate-600 focus:border-indigo-500 cursor-pointer"
      >
        <option value="en">🇺🇸 English</option>
        <option value="hi">🇮🇳 हिन्दी</option>
      </select>
    </div>
  );
};
