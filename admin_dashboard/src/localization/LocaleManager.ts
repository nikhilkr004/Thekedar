export class LocaleManager {
  private static CACHE_KEY = "preferred_language";

  static getCachedLocale(): string {
    if (typeof window !== "undefined") {
      return localStorage.getItem(this.CACHE_KEY) || "en";
    }
    return "en";
  }

  static cacheLocale(locale: string) {
    if (typeof window !== "undefined") {
      localStorage.setItem(this.CACHE_KEY, locale);
    }
  }

  static async syncLocaleToFirebase(locale: string): Promise<void> {
    // No-op in admin dashboard (uses Local Storage caching and Supabase)
  }

  // Locales formatter utility
  static formatCurrency(amount: number, locale: string = "en-IN", currency: string = "INR"): string {
    return new Intl.NumberFormat(locale, {
      style: "currency",
      currency: currency
    }).format(amount);
  }

  static formatDate(date: Date, locale: string = "en-IN", options?: Intl.DateTimeFormatOptions): string {
    const defaultOptions: Intl.DateTimeFormatOptions = options || {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    };
    return new Intl.DateTimeFormat(locale, defaultOptions).format(date);
  }

  static formatNumber(value: number, locale: string = "en-IN"): string {
    return new Intl.NumberFormat(locale).format(value);
  }
}
