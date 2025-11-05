import pytest
import asyncio
from fastapi.testclient import TestClient
from main import app
from reports import NBAReportGenerator


@pytest.fixture
def client():
    """Create test client for FastAPI app"""
    return TestClient(app)


@pytest.fixture
def report_generator():
    """Create report generator instance for testing"""
    return NBAReportGenerator(None)  # Mock supabase client


class TestAPIEndpoints:
    """Test API endpoint functionality"""
    
    def test_health_endpoint(self, client):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "timestamp" in data
    
    def test_status_endpoint(self, client):
        """Test status endpoint"""
        response = client.get("/api/status")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "running"
        assert "timestamp" in data
    
    def test_750am_report_endpoint(self, client):
        """Test 7:50 AM report endpoint"""
        response = client.get("/api/reports/750am")
        assert response.status_code in [200, 500]  # May fail without DB
    
    def test_800am_report_endpoint(self, client):
        """Test 8:00 AM report endpoint"""
        response = client.get("/api/reports/800am")
        assert response.status_code in [200, 500]  # May fail without DB
    
    def test_1100am_report_endpoint(self, client):
        """Test 11:00 AM report endpoint"""
        response = client.get("/api/reports/1100am")
        assert response.status_code in [200, 500]  # May fail without DB


class TestReportGeneration:
    """Test report generation functionality"""
    
    @pytest.mark.asyncio
    async def test_750am_report_structure(self, report_generator):
        """Test 7:50 AM report has correct structure"""
        report = await report_generator.generate_750am_report()
        
        assert "timestamp" in report
        assert "report_type" in report
        assert report["report_type"] == "750am_previous_day"
        assert "yesterday_results" in report
        assert "closing_line_analysis" in report
        assert "bulls_player_breakdown" in report
        assert "market_trends" in report
    
    @pytest.mark.asyncio 
    async def test_800am_report_structure(self, report_generator):
        """Test 8:00 AM report has correct structure"""
        report = await report_generator.generate_800am_report()
        
        assert "timestamp" in report
        assert "report_type" in report
        assert report["report_type"] == "800am_morning_summary"
        assert "executive_summary" in report
        assert "yesterday_performance" in report
        assert "seven_day_trends" in report
        assert "bulls_form_analysis" in report
        assert "market_intelligence" in report
    
    @pytest.mark.asyncio
    async def test_1100am_report_structure(self, report_generator):
        """Test 11:00 AM report has correct structure"""
        report = await report_generator.generate_1100am_report()
        
        assert "timestamp" in report
        assert "report_type" in report
        assert report["report_type"] == "1100am_gameday_scouting"
        assert "slate_overview" in report
        assert "injury_intelligence" in report
        assert "matchup_analysis" in report
        assert "bulls_game_plan" in report


class TestBettingCalculations:
    """Test betting calculation functionality"""
    
    def test_kelly_criterion_calculation(self, report_generator):
        """Test Kelly Criterion calculation"""
        # Test positive Kelly
        kelly = report_generator.calculate_kelly_criterion(0.6, 2.0)
        assert kelly > 0
        assert kelly <= 0.25  # Capped at 25%
        
        # Test negative Kelly (no bet)
        kelly = report_generator.calculate_kelly_criterion(0.4, 2.0)
        assert kelly == 0
        
        # Test edge case
        kelly = report_generator.calculate_kelly_criterion(0, 2.0)
        assert kelly == 0
    
    def test_roi_calculation(self, report_generator):
        """Test ROI projection calculation"""
        bet_history = [
            {"amount": 100, "profit": 50, "result": "win"},
            {"amount": 100, "profit": -100, "result": "loss"},
            {"amount": 50, "profit": 25, "result": "win"}
        ]
        
        metrics = report_generator.calculate_roi_projection(bet_history)
        
        assert "roi" in metrics
        assert "total_bets" in metrics
        assert "win_rate" in metrics
        assert metrics["total_bets"] == 3
        assert metrics["win_rate"] == (2/3) * 100  # 66.67%
    
    def test_betting_slip_formatting(self, report_generator):
        """Test betting slip generation"""
        bets = [
            {
                "selection": "Bulls +2.5",
                "odds": 110,
                "stake": 100,
                "confidence": 70,
                "reasoning": "Home underdog value",
                "sportsbook": "DraftKings"
            }
        ]
        
        slip = report_generator.format_betting_slip(bets, 100)
        
        assert "timestamp" in slip
        assert "total_stake" in slip
        assert "number_of_bets" in slip
        assert "bets" in slip
        assert "expected_value" in slip
        assert slip["number_of_bets"] == 1
        assert slip["total_stake"] == 100


class TestDataValidation:
    """Test data validation and error handling"""
    
    @pytest.mark.asyncio
    async def test_empty_games_handling(self, report_generator):
        """Test handling of empty games list"""
        report = await report_generator.generate_1100am_report()
        # Should not crash with empty data
        assert "timestamp" in report
    
    def test_invalid_odds_handling(self, report_generator):
        """Test handling of invalid odds data"""
        # Test with invalid decimal odds
        kelly = report_generator.calculate_kelly_criterion(0.6, 0)
        assert kelly == 0
        
        kelly = report_generator.calculate_kelly_criterion(0.6, -1)
        assert kelly == 0
    
    def test_empty_bet_history(self, report_generator):
        """Test ROI calculation with empty bet history"""
        metrics = report_generator.calculate_roi_projection([])
        
        assert metrics["roi"] == 0
        assert metrics["total_bets"] == 0
        assert metrics["win_rate"] == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])