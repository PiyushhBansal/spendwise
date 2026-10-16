import React, { useCallback, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { api } from "./api.js";
import "./styles.css";

const CATEGORIES = ["food", "transport", "housing", "utilities", "health", "entertainment", "shopping", "other"];
const today = () => new Date().toISOString().slice(0, 10);
const emptyForm = () => ({ title: "", amount: "", category: "food", spent_on: today(), note: "" });
const money = (v) => Number(v).toLocaleString("en-IN", { style: "currency", currency: "INR" });

function ExpenseForm({ initial, onSubmit, onCancel, submitLabel }) {
  const [form, setForm] = useState(initial);
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    const ok = await onSubmit({ ...form, note: form.note || null });
    if (ok && !onCancel) setForm(emptyForm());
  };

  return (
    <form className="expense-form" onSubmit={submit}>
      <input placeholder="What did you spend on?" value={form.title} onChange={set("title")} required maxLength={120} />
      <input type="number" step="0.01" min="0.01" placeholder="Amount" value={form.amount} onChange={set("amount")} required />
      <select value={form.category} onChange={set("category")}>
        {CATEGORIES.map((c) => (
          <option key={c} value={c}>{c}</option>
        ))}
      </select>
      <input type="date" value={form.spent_on} onChange={set("spent_on")} required />
      <input placeholder="Note (optional)" value={form.note || ""} onChange={set("note")} maxLength={500} />
      <div className="form-actions">
        <button type="submit" className="primary">{submitLabel}</button>
        {onCancel && <button type="button" onClick={onCancel}>Cancel</button>}
      </div>
    </form>
  );
}

function SummaryPanel({ summary }) {
  if (!summary) return null;
  const max = Math.max(...summary.by_category.map((c) => Number(c.total)), 1);
  return (
    <section className="card summary">
      <div className="stats">
        <div><span className="label">Total spent</span><strong>{money(summary.total)}</strong></div>
        <div><span className="label">Expenses</span><strong>{summary.count}</strong></div>
      </div>
      <ul className="bars">
        {summary.by_category.map((c) => (
          <li key={c.category}>
            <span className={`tag tag-${c.category}`}>{c.category}</span>
            <div className="bar"><div style={{ width: `${(Number(c.total) / max) * 100}%` }} /></div>
            <span className="amount">{money(c.total)}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}

function App() {
  const [expenses, setExpenses] = useState([]);
  const [summary, setSummary] = useState(null);
  const [filter, setFilter] = useState("");
  const [editingId, setEditingId] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      const [list, sum] = await Promise.all([api.list(filter), api.summary()]);
      setExpenses(list);
      setSummary(sum);
      setError("");
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const run = (fn) => async (...args) => {
    try {
      await fn(...args);
      await refresh();
      return true;
    } catch (e) {
      setError(e.message);
      return false;
    }
  };

  const create = run((data) => api.create(data));
  const update = run(async (id, data) => {
    await api.update(id, data);
    setEditingId(null);
  });
  const remove = run((id) => api.remove(id));

  return (
    <main className="container">
      <header>
        <h1>SpendWise</h1>
        <p>Track where your money goes.</p>
      </header>

      {error && <div className="error" role="alert">{error}</div>}

      <section className="card">
        <h2>Add expense</h2>
        <ExpenseForm initial={emptyForm()} onSubmit={create} submitLabel="Add" />
      </section>

      <SummaryPanel summary={summary} />

      <section className="card">
        <div className="list-header">
          <h2>Expenses</h2>
          <select value={filter} onChange={(e) => setFilter(e.target.value)} aria-label="Filter by category">
            <option value="">All categories</option>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        </div>

        {loading ? (
          <p className="muted">Loading…</p>
        ) : expenses.length === 0 ? (
          <p className="muted">No expenses yet. Add your first one above.</p>
        ) : (
          <ul className="expenses">
            {expenses.map((e) =>
              editingId === e.id ? (
                <li key={e.id} className="editing">
                  <ExpenseForm
                    initial={e}
                    onSubmit={(data) => update(e.id, data)}
                    onCancel={() => setEditingId(null)}
                    submitLabel="Save"
                  />
                </li>
              ) : (
                <li key={e.id}>
                  <div className="info">
                    <strong>{e.title}</strong>
                    <span className="meta">
                      <span className={`tag tag-${e.category}`}>{e.category}</span> {e.spent_on}
                      {e.note && <> · {e.note}</>}
                    </span>
                  </div>
                  <span className="amount">{money(e.amount)}</span>
                  <div className="row-actions">
                    <button onClick={() => setEditingId(e.id)}>Edit</button>
                    <button className="danger" onClick={() => remove(e.id)}>Delete</button>
                  </div>
                </li>
              )
            )}
          </ul>
        )}
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
