package com.thekedar.core.localization

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await

class LanguageRepository(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance(),
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) {
    suspend fun syncLanguageToFirebase(langCode: String): Result<Unit> {
        return try {
            val user = auth.currentUser
            if (user != null) {
                val data = mapOf(
                    "preferred_language" to langCode,
                    "language_updated_at" to System.currentTimeMillis(),
                    "language_source" to "android"
                )
                firestore.collection("users").document(user.uid)
                    .update(data)
                    .await()
            }
            Result.success(Unit)
        } catch (e: Exception) {
            // Document might not exist yet, fallback to set with merge
            try {
                val user = auth.currentUser
                if (user != null) {
                    val data = mapOf(
                        "preferred_language" to langCode,
                        "language_updated_at" to System.currentTimeMillis(),
                        "language_source" to "android"
                    )
                    firestore.collection("users").document(user.uid)
                        .set(data, com.google.firebase.firestore.SetOptions.merge())
                        .await()
                }
                Result.success(Unit)
            } catch (ex: Exception) {
                Result.failure(ex)
            }
        }
    }

    suspend fun fetchLanguageFromFirebase(): Result<String?> {
        return try {
            val user = auth.currentUser
            if (user != null) {
                val doc = firestore.collection("users").document(user.uid).get().await()
                val lang = doc.getString("preferred_language")
                Result.success(lang)
            } else {
                Result.success(null)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
