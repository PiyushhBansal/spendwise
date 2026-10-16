def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_create_expense(client, sample_expense):
    res = client.post("/api/expenses", json=sample_expense)
    assert res.status_code == 201
    body = res.json()
    assert body["id"] > 0
    assert body["title"] == "Groceries"
    assert body["amount"] == "42.50"
    assert body["category"] == "food"


def test_create_expense_rejects_negative_amount(client, sample_expense):
    res = client.post("/api/expenses", json={**sample_expense, "amount": "-5"})
    assert res.status_code == 422


def test_create_expense_rejects_unknown_category(client, sample_expense):
    res = client.post("/api/expenses", json={**sample_expense, "category": "crypto"})
    assert res.status_code == 422


def test_list_expenses_with_category_filter(client, sample_expense):
    client.post("/api/expenses", json=sample_expense)
    client.post("/api/expenses", json={**sample_expense, "title": "Metro card", "category": "transport"})

    all_items = client.get("/api/expenses").json()
    assert len(all_items) == 2

    food = client.get("/api/expenses", params={"category": "food"}).json()
    assert [e["title"] for e in food] == ["Groceries"]


def test_get_expense_by_id_and_404(client, sample_expense):
    created = client.post("/api/expenses", json=sample_expense).json()
    assert client.get(f"/api/expenses/{created['id']}").json()["title"] == "Groceries"
    assert client.get("/api/expenses/9999").status_code == 404


def test_update_expense(client, sample_expense):
    created = client.post("/api/expenses", json=sample_expense).json()
    res = client.put(f"/api/expenses/{created['id']}", json={"amount": "50.00", "title": "Big groceries"})
    assert res.status_code == 200
    body = res.json()
    assert body["amount"] == "50.00"
    assert body["title"] == "Big groceries"
    assert body["category"] == "food"


def test_delete_expense(client, sample_expense):
    created = client.post("/api/expenses", json=sample_expense).json()
    assert client.delete(f"/api/expenses/{created['id']}").status_code == 204
    assert client.get(f"/api/expenses/{created['id']}").status_code == 404
    assert client.delete(f"/api/expenses/{created['id']}").status_code == 404


def test_summary_groups_by_category(client, sample_expense):
    client.post("/api/expenses", json=sample_expense)
    client.post("/api/expenses", json={**sample_expense, "amount": "7.50"})
    client.post("/api/expenses", json={**sample_expense, "category": "transport", "amount": "20.00"})

    body = client.get("/api/summary").json()
    assert body["count"] == 3
    assert body["total"] == "70.00"
    totals = {c["category"]: c["total"] for c in body["by_category"]}
    assert totals == {"food": "50.00", "transport": "20.00"}


def test_metrics_endpoint_exposes_prometheus_format(client, sample_expense):
    client.post("/api/expenses", json=sample_expense)
    res = client.get("/metrics")
    assert res.status_code == 200
    assert "http_requests_total" in res.text
