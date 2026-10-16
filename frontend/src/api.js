const BASE = "/api";

async function request(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const detail = Array.isArray(body.detail) ? body.detail.map((d) => d.msg).join(", ") : body.detail;
    throw new Error(detail || `Request failed (${res.status})`);
  }
  return res.status === 204 ? null : res.json();
}

export const api = {
  list: (category) => request(`/expenses${category ? `?category=${category}` : ""}`),
  create: (data) => request("/expenses", { method: "POST", body: JSON.stringify(data) }),
  update: (id, data) => request(`/expenses/${id}`, { method: "PUT", body: JSON.stringify(data) }),
  remove: (id) => request(`/expenses/${id}`, { method: "DELETE" }),
  summary: () => request("/summary"),
};
