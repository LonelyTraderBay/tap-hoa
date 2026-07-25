import { existsSync } from 'fs';
import { ReportsService } from './reports.service';

type PeriodPdfFontHarness = {
  resolvePeriodPdfFontPath(): string | null;
  usePeriodPdfFont(doc: {
    registerFont(name: string, src: string): unknown;
    font(name: string): unknown;
  }): void;
};

describe('ReportsService period PDF font', () => {
  it('registers the bundled NotoSans Regular font', () => {
    const service = new ReportsService(
      {} as ConstructorParameters<typeof ReportsService>[0],
    ) as unknown as PeriodPdfFontHarness;
    const fontPath = service.resolvePeriodPdfFontPath();
    if (!fontPath) {
      throw new Error('Expected bundled period PDF font to resolve');
    }
    expect(fontPath.replace(/\\/g, '/')).toContain(
      'assets/fonts/NotoSans-Regular.ttf',
    );
    expect(existsSync(fontPath)).toBe(true);

    const registeredFonts: Array<{ name: string; src: string }> = [];
    let selectedFont: string | undefined;
    const doc = {
      registerFont(name: string, src: string) {
        registeredFonts.push({ name, src });
        return doc;
      },
      font(name: string) {
        selectedFont = name;
        return doc;
      },
    };

    service.usePeriodPdfFont(doc);

    expect(registeredFonts).toEqual([{ name: 'NotoSans', src: fontPath }]);
    expect(selectedFont).toBe('NotoSans');
  });
});
