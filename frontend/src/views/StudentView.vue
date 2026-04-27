<template>
  <div class="min-h-screen bg-gray-50">
    <div class="max-w-7xl mx-auto py-3 sm:px-6 lg:px-8">
      <div class="px-4 py-3 sm:px-0">
        <div class="border-b border-gray-200 pb-2 mb-5">
          <h1 class="text-3xl font-bold text-gray-900">学习中心</h1>
          <p class="mt-2 text-sm text-gray-500">
            探索课程、完成作业和跟踪您的学习进度
          </p>
        </div>

        <!-- 欢迎页 -->
        <div v-if="activeTab === 'dashboard'">
          <WelcomeMessage v-model:activeTab="activeTab" />
        </div>

        <!-- 课程列表 -->
        <div v-if="activeTab === 'courses'">
          <CourseList />
        </div>

        <!-- 学习分析 -->
        <div v-if="activeTab === 'analytics'">
          <LearningAnalytics :user-id="userId || ''" />
        </div>

        <!-- AI助手 -->
        <div v-if="activeTab === 'ai-assistant'">
          <AIAssistant :user-id="userId || ''" />
        </div>

        <!-- 知识库 -->
        <div v-if="activeTab === 'knowledge-base'">
          <KnowledgeBase />
        </div>

        <!-- AI自测测验 -->
        <div v-if="activeTab === 'ai-quiz'">
          <TestAIQuizView />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useRoute, useRouter } from 'vue-router';
import CourseList from '@/components/course/CourseList.vue';
import AIAssistant from '@/components/ai/AIAssistant.vue';
import LearningAnalytics from '@/components/analytics/LearningAnalytics.vue';
import KnowledgeBase from '@/components/rag/KnowledgeBase.vue';
import WelcomeMessage from '@/components/WelcomeMessage.vue';
import TestAIQuizView from '@/views/TestAIQuizView.vue';
import { studentTabs } from '@/config/dashboardTabs';

const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const userId = computed(() => authStore.user?.id);

const tabs = studentTabs;
const activeTab = computed({
  get: () => {
    const tab = route.query.activeTab;
    return typeof tab === 'string' && tabs.some(item => item.id === tab) ? tab : 'dashboard';
  },
  set: (tabId: string) => {
    router.replace({
      query: {
        ...route.query,
        activeTab: tabId
      }
    });
  }
});

// 示例数据
const enrolledCourses = ref([
  {
    id: 1,
    title: 'Python编程基础',
    description: '学习Python编程的基本概念和语法',
    progress: 45
  },
  {
    id: 2,
    title: '数据结构与算法',
    description: '掌握常见数据结构和算法',
    progress: 20
  }
]);

const learningStats = ref({
  completedLessons: 12,
  completedAssignments: 8,
  averageScore: 85
});

// 这里可以添加获取课程和学习数据的API调用
</script>

<style scoped>
.btn {
  @apply px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2;
}

.btn-primary {
  @apply text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500;
}
</style> 
