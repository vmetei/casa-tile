import type { APIRoute, GetStaticPaths } from 'astro';
import { getProducts } from '../../lib/data';
import { tileSvg } from '../../lib/tile-svg';

export const getStaticPaths: GetStaticPaths = async () => {
  const products = await getProducts();
  return products.map((p) => ({ params: { slug: p.id } }));
};

export const GET: APIRoute = async ({ params }) => {
  const products = await getProducts();
  const product = products.find((p) => p.id === params.slug);
  if (!product) return new Response('Not Found', { status: 404 });

  const svg = tileSvg(
    product.data.pattern,
    product.data.baseColor,
    product.data.accentColor,
    product.id
  );

  return new Response(svg, {
    headers: {
      'Content-Type': 'image/svg+xml',
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
  });
};
