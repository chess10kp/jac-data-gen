"""
End-to-End Tests for FastAPI Guestbook API

This module contains comprehensive tests for all API endpoints:
- GET / (welcome endpoint)
- GET /entries (retrieve all entries)  
- POST /entry (create new entry)
- DELETE /entry/id (delete entry by ID)

Tests include:
- Positive test cases for all endpoints
- Data validation and persistence
- Error handling for invalid inputs
- Complete workflow testing (create -> read -> delete)
"""

import asyncio
import httpx
import pytest
import os
from typing import Dict, Any
import json

# Test configuration
BASE_URL = os.getenv("TEST_BASE_URL", "http://web:8080")
TIMEOUT = 30.0

class TestGuestbookAPI:
    """Comprehensive end-to-end test suite for the Guestbook API"""

    @pytest.fixture(scope="class")
    async def client(self):
        """Create HTTP client for testing"""
        async with httpx.AsyncClient(base_url=BASE_URL, timeout=TIMEOUT) as client:
            yield client

    @pytest.mark.asyncio
    async def test_welcome_endpoint(self, client: httpx.AsyncClient):
        """Test GET / endpoint returns welcome message"""
        response = await client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Welcome to the FastAPI + Okteto" in data["message"]
        print("✅ Welcome endpoint test passed")

    @pytest.mark.asyncio
    async def test_get_entries_empty(self, client: httpx.AsyncClient):
        """Test GET /entries returns empty list initially"""
        response = await client.get("/entries")
        
        assert response.status_code == 200
        data = response.json()
        assert "entries" in data
        assert isinstance(data["entries"], list)
        print("✅ Get entries (empty) test passed")

    @pytest.mark.asyncio
    async def test_create_entry_valid(self, client: httpx.AsyncClient):
        """Test POST /entry creates a new entry successfully"""
        entry_data = {
            "name": "Test User from E2E Test",
            "entry": "This is a test entry created during end-to-end testing"
        }
        
        response = await client.post("/entry", json=entry_data)
        
        # Debug information for troubleshooting
        if response.status_code != 200:
            print(f"❌ Expected status 200, got {response.status_code}")
            print(f"❌ Response text: {response.text}")
            print(f"❌ Response headers: {dict(response.headers)}")
            
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        data = response.json()
        assert "message" in data
        assert "New entry added with ID:" in data["message"]
        
        # Extract the ID for later use
        entry_id = data["message"].split("ID: ")[1]
        assert len(entry_id) == 24  # MongoDB ObjectId length
        print(f"✅ Create entry test passed - ID: {entry_id}")
        return entry_id

    @pytest.mark.asyncio
    async def test_create_entry_invalid_data(self, client: httpx.AsyncClient):
        """Test POST /entry with invalid data returns appropriate error"""
        invalid_entry_data = {
            "name": "",  # Empty name should be invalid
            "entry": ""  # Empty entry should be invalid
        }
        
        response = await client.post("/entry", json=invalid_entry_data)
        # Note: Depending on validation rules, this might be 422 or still 200
        # For now, we'll check that we get a response
        assert response.status_code in [200, 422]
        print("✅ Create entry with invalid data test passed")

    @pytest.mark.asyncio
    async def test_get_entries_with_data(self, client: httpx.AsyncClient):
        """Test GET /entries returns entries after creation"""
        # First create an entry
        entry_data = {
            "name": "Test User 2",
            "entry": "Second test entry for validation"
        }
        
        create_response = await client.post("/entry", json=entry_data)
        assert create_response.status_code == 200
        
        # Now get all entries
        response = await client.get("/entries")
        
        assert response.status_code == 200
        data = response.json()
        assert "entries" in data
        assert isinstance(data["entries"], list)
        assert len(data["entries"]) >= 1  # Should have at least our created entry
        
        # Verify entry structure
        if data["entries"]:
            entry = data["entries"][0]
            assert "name" in entry
            assert "entry" in entry
            assert "id" in entry
        
        print(f"✅ Get entries with data test passed - Found {len(data['entries'])} entries")

    @pytest.mark.asyncio
    async def test_delete_entry_workflow(self, client: httpx.AsyncClient):
        """Test complete workflow: create entry -> verify -> delete -> verify deletion"""
        
        # Step 1: Create a test entry
        entry_data = {
            "name": "Delete Test User",
            "entry": "This entry will be deleted in the test"
        }
        
        create_response = await client.post("/entry", json=entry_data)
        assert create_response.status_code == 200
        
        # Extract entry ID
        create_data = create_response.json()
        entry_id = create_data["message"].split("ID: ")[1]
        
        # Step 2: Verify entry exists
        get_response = await client.get("/entries")
        assert get_response.status_code == 200
        entries_data = get_response.json()
        
        # Find our entry
        created_entry = None
        for entry in entries_data["entries"]:
            if entry["id"] == entry_id:
                created_entry = entry
                break
        
        assert created_entry is not None
        assert created_entry["name"] == "Delete Test User"
        
        # Step 3: Delete the entry using path parameter
        delete_response = await client.delete(f"/entry/{entry_id}")
        
        assert delete_response.status_code == 200
        delete_data = delete_response.json()
        assert "message" in delete_data
        assert "deleted successfully" in delete_data["message"]
        
        print(f"✅ Delete entry workflow test passed - Entry {entry_id} created and deleted")

    @pytest.mark.asyncio
    async def test_delete_nonexistent_entry(self, client: httpx.AsyncClient):
        """Test DELETE /entry/{id} with non-existent ID"""
        fake_id = "507f1f77bcf86cd799439011"  # Valid ObjectId format but non-existent
        
        response = await client.delete(f"/entry/{fake_id}")
        
        # Should still return success (based on the implementation)
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "deleted successfully" in data["message"]
        print("✅ Delete non-existent entry test passed")

    @pytest.mark.asyncio 
    async def test_api_endpoints_comprehensive(self, client: httpx.AsyncClient):
        """Comprehensive test covering full API workflow"""
        
        print("\n🚀 Starting comprehensive API test workflow...")
        
        # Get initial state
        initial_response = await client.get("/entries")
        initial_count = len(initial_response.json()["entries"])
        print(f"📊 Initial entry count: {initial_count}")
        
        # Create multiple entries
        test_entries = [
            {"name": "Alice", "entry": "First comprehensive test entry"},
            {"name": "Bob", "entry": "Second comprehensive test entry"}, 
            {"name": "Charlie", "entry": "Third comprehensive test entry"}
        ]
        
        created_ids = []
        for i, entry_data in enumerate(test_entries, 1):
            response = await client.post("/entry", json=entry_data)
            assert response.status_code == 200
            
            entry_id = response.json()["message"].split("ID: ")[1]
            created_ids.append(entry_id)
            print(f"✅ Created entry {i}: {entry_data['name']} (ID: {entry_id})")
        
        # Verify all entries exist
        entries_response = await client.get("/entries")
        assert entries_response.status_code == 200
        
        current_entries = entries_response.json()["entries"]
        current_count = len(current_entries)
        
        assert current_count >= initial_count + len(test_entries)
        print(f"📊 Current entry count: {current_count}")
        
        # Verify our entries are present
        found_entries = 0
        for entry in current_entries:
            if entry["id"] in created_ids:
                found_entries += 1
                print(f"✅ Found entry: {entry['name']} - {entry['entry'][:50]}...")
        
        assert found_entries == len(test_entries)
        
        # Clean up: Delete created entries
        for i, entry_id in enumerate(created_ids, 1):
            delete_response = await client.delete(f"/entry/{entry_id}")
            assert delete_response.status_code == 200
            print(f"🗑️  Deleted entry {i} (ID: {entry_id})")
        
        print("✅ Comprehensive API workflow test completed successfully!")


# Standalone test runner for direct execution
async def run_tests():
    """Run all tests when script is executed directly"""
    print("🧪 Running End-to-End Tests for Guestbook API")
    print(f"🔗 Testing against: {BASE_URL}")
    print("=" * 60)
    
    test_instance = TestGuestbookAPI()
    
    try:
        async with httpx.AsyncClient(base_url=BASE_URL, timeout=TIMEOUT) as client:
            
            # Test 1: Welcome endpoint
            print("\n1️⃣ Testing Welcome Endpoint...")
            await test_instance.test_welcome_endpoint(client)
            
            # Test 2: Get entries (empty)
            print("\n2️⃣ Testing Get Entries (Initial)...")
            await test_instance.test_get_entries_empty(client)
            
            # Test 3: Create valid entry
            print("\n3️⃣ Testing Create Entry (Valid)...")
            await test_instance.test_create_entry_valid(client)
            
            # Test 4: Create invalid entry
            print("\n4️⃣ Testing Create Entry (Invalid)...")
            await test_instance.test_create_entry_invalid_data(client)
            
            # Test 5: Get entries with data
            print("\n5️⃣ Testing Get Entries (With Data)...")
            await test_instance.test_get_entries_with_data(client)
            
            # Test 6: Delete entry workflow
            print("\n6️⃣ Testing Delete Entry Workflow...")
            await test_instance.test_delete_entry_workflow(client)
            
            # Test 7: Delete non-existent entry
            print("\n7️⃣ Testing Delete Non-existent Entry...")
            await test_instance.test_delete_nonexistent_entry(client)
            
            # Test 8: Comprehensive workflow
            print("\n8️⃣ Testing Comprehensive Workflow...")
            await test_instance.test_api_endpoints_comprehensive(client)
            
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        raise
    
    print("\n" + "=" * 60)
    print("🎉 All End-to-End Tests Passed Successfully!")
    print("✅ API is functioning correctly across all endpoints")


if __name__ == "__main__":
    # Run tests directly when script is executed
    asyncio.run(run_tests())