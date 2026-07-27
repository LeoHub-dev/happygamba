import type { Request, Response, NextFunction } from 'express';

/** Adds `X-Response-Time` before the body is sent; warns if >50ms. */
export function timingMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = process.hrtime.bigint();

  const originalJson = res.json.bind(res);
  res.json = ((body: unknown) => {
    const ms = Number(process.hrtime.bigint() - start) / 1e6;
    if (!res.headersSent) {
      res.setHeader('X-Response-Time', `${ms.toFixed(1)}ms`);
    }
    if (ms > 50) {
      console.warn(`[slow] ${req.method} ${req.path} ${ms.toFixed(1)}ms`);
    }
    return originalJson(body);
  }) as Response['json'];

  next();
}
