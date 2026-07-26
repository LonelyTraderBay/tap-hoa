import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import {
  TAP_HOA_LOCAL_API_PORT,
  TAP_HOA_PROJECT_ID,
  assertTapHoaLocalIdentity,
} from './config/tap-hoa.identity';

async function bootstrap() {
  assertTapHoaLocalIdentity();
  const app = await NestFactory.create(AppModule);
  const port = Number(process.env.PORT) || TAP_HOA_LOCAL_API_PORT;
  await app.listen(port);
  if (process.env.NODE_ENV !== 'production') {
    console.log(`[${TAP_HOA_PROJECT_ID}] API listening on http://127.0.0.1:${port}`);
  }
}
bootstrap();
