package dev.nutritiontracker.app.litertgemma

import org.junit.Assert.assertTrue
import org.junit.Test

class SanityTest {
    @Test
    fun testSanity() {
        assertTrue("Sanity test for M0 passes", true)
    }

    @Test
    fun testApiSmokeTestCompiles() {
        val smoke = ApiSmokeTest()
        val result = smoke.smokeTest("dummy.litertlm", "dummy.jpg", null)
        assertTrue(result.contains("dummy.litertlm"))
    }
}
