from ai import ensemble


class DummyXGB:
    def predict_proba(self, values):
        assert len(values[0]) == 5
        return [[0.2, 0.8]]


class DummyNN:
    def predict(self, values):
        assert len(values[0]) == 5
        return [0.5]


def test_predict_weighted_score(monkeypatch):
    monkeypatch.setattr(ensemble, "_load_models", lambda: (DummyXGB(), DummyNN()))

    result = ensemble.predict([0.1, 0.2, 0.3, 0.4, 0.5])

    assert round(result["score"], 4) == 0.68
    assert result["risk"] == "WARNING"
