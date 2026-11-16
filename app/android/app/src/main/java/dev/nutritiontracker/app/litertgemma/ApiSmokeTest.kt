package dev.nutritiontracker.app.litertgemma

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.ExperimentalApi
import com.google.ai.edge.litertlm.ExperimentalFlags
import com.google.ai.edge.litertlm.SamplerConfig
import com.google.ai.edge.litertlm.SpeculativeDecodingConfig
import com.google.ai.edge.litertlm.SpeculativeDecodingMode
import com.google.ai.edge.litertlm.ThinkingConfig

/**
 * Compile smoke test validating that all required LiteRT-LM v0.19.1 types,
 * constructors, and experimental APIs link cleanly against Kotlin 2.2.0.
 */
@OptIn(ExperimentalApi::class)
class ApiSmokeTest {
    fun smokeTest(modelPath: String, imagePath: String, conversation: Conversation?): String {
        // Set experimental flags before engine creation
        ExperimentalFlags.enableBenchmark = true
        ExperimentalFlags.visualTokenBudget = 280

        val cpuBackend = Backend.CPU(threadCount = 4)
        val gpuBackend = Backend.GPU()

        val engineConfig = EngineConfig(
            modelPath = modelPath,
            backend = cpuBackend,
            visionBackend = gpuBackend,
            maxNumTokens = 1024,
            maxNumImages = 1,
            speculativeDecodingConfig = SpeculativeDecodingConfig(
                mode = SpeculativeDecodingMode.OFF
            )
        )

        val conversationConfig = ConversationConfig(
            samplerConfig = SamplerConfig(
                topK = 40,
                topP = 0.95,
                temperature = 0.2,
                seed = 42
            ),
            maxOutputToken = 512,
            thinkingConfig = ThinkingConfig(enableThinking = false)
        )

        val contents = Contents.of(
            Content.ImageFile(imagePath),
            Content.Text("test prompt")
        )

        conversation?.let { conv ->
            conv.cancelProcess()
            val benchmarkInfo = conv.getBenchmarkInfo()
            return "Init: ${benchmarkInfo.initTimeInSecond}, contents: ${contents.contents.size}, engine: ${engineConfig.backend.name}, conv: ${conversationConfig.maxOutputToken}"
        }

        return "Engine config created for ${engineConfig.modelPath}"
    }
}
