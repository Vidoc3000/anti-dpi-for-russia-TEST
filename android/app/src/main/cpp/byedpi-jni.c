#include <android/log.h>
#include <getopt.h>
#include <jni.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

#include "byedpi/params.h"

#define TAG "AntiDpiByedpi"

extern int server_fd;
extern int main(int argc, char **argv);
extern int optind;
extern int opterr;
extern int optopt;
extern char *optarg;

static pthread_mutex_t proxy_mutex = PTHREAD_MUTEX_INITIALIZER;
static bool proxy_running;
static JNIEnv *proxy_worker_env;
static jclass proxy_log_class;
static jmethodID proxy_log_method;

void android_proxy_log(const char *message) {
    JNIEnv *env = proxy_worker_env;
    if (!env || !message) return;
    if (!proxy_log_class) {
        jclass local = (*env)->FindClass(env, "ru/antidpi/mobile/NativeByedpiProxy");
        if (!local) {
            if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
            return;
        }
        proxy_log_class = (jclass) (*env)->NewGlobalRef(env, local);
        (*env)->DeleteLocalRef(env, local);
        if (!proxy_log_class) return;
        proxy_log_method = (*env)->GetStaticMethodID(env, proxy_log_class,
                "onNativeLog", "(Ljava/lang/String;)V");
        if (!proxy_log_method) {
            if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
            (*env)->DeleteGlobalRef(env, proxy_log_class);
            proxy_log_class = NULL;
            return;
        }
    }
    jstring value = (*env)->NewStringUTF(env, message);
    if (!value) return;
    (*env)->CallStaticVoidMethod(env, proxy_log_class, proxy_log_method, value);
    (*env)->DeleteLocalRef(env, value);
    if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
}

static void reset_params(void) {
    memset(&params, 0, sizeof(params));
    params.await_int = 10;
    params.ipv6 = 1;
    params.resolve = 1;
    params.udp = 1;
    params.max_open = 512;
    params.bfsize = 16384;
    params.baddr.in6.sin6_family = AF_INET6;
    params.laddr.in.sin_family = AF_INET;
    params.debug = 0;
}

int __wrap_daemon(int nochdir, int noclose) {
    (void) nochdir;
    (void) noclose;
    __android_log_print(ANDROID_LOG_ERROR, TAG, "daemon mode is not available in the Android worker");
    return -1;
}

JNIEXPORT jint JNICALL
Java_ru_antidpi_mobile_NativeByedpiProxy_nativeStartProxy(
        JNIEnv *env, __attribute__((unused)) jclass clazz, jobjectArray arguments) {
    pthread_mutex_lock(&proxy_mutex);
    if (proxy_running) {
        pthread_mutex_unlock(&proxy_mutex);
        return -1;
    }
    proxy_running = true;
    server_fd = -1;
    optind = 0;
    opterr = 0;
    optopt = 0;
    optarg = NULL;
    reset_params();
    pthread_mutex_unlock(&proxy_mutex);

    int result = -1;
    const jsize count = (*env)->GetArrayLength(env, arguments);
    char **argv = calloc((size_t) count + 2, sizeof(char *));
    if (!argv) {
        pthread_mutex_lock(&proxy_mutex);
        proxy_running = false;
        pthread_mutex_unlock(&proxy_mutex);
        return -1;
    }
    argv[0] = strdup("antidpi-bye");
    if (!argv[0]) goto cleanup;

    for (jsize i = 0; i < count; i++) {
        jstring item = (jstring) (*env)->GetObjectArrayElement(env, arguments, i);
        if (!item) goto cleanup;
        const char *utf = (*env)->GetStringUTFChars(env, item, NULL);
        if (utf) {
            argv[i + 1] = strdup(utf);
            (*env)->ReleaseStringUTFChars(env, item, utf);
        }
        (*env)->DeleteLocalRef(env, item);
        if (!argv[i + 1]) goto cleanup;
    }

    __android_log_print(ANDROID_LOG_INFO, TAG, "starting native ByeDPI proxy (%d arguments)", count);
    proxy_worker_env = env;
    result = main((int) count + 1, argv);
    proxy_worker_env = NULL;
    if (proxy_log_class) {
        (*env)->DeleteGlobalRef(env, proxy_log_class);
        proxy_log_class = NULL;
        proxy_log_method = NULL;
    }
    __android_log_print(ANDROID_LOG_INFO, TAG, "native ByeDPI proxy exited: %d", result);

cleanup:
    for (jsize i = 0; i < count + 1; i++) free(argv[i]);
    free(argv);
    pthread_mutex_lock(&proxy_mutex);
    server_fd = -1;
    proxy_running = false;
    reset_params();
    pthread_mutex_unlock(&proxy_mutex);
    return result;
}

JNIEXPORT jint JNICALL
Java_ru_antidpi_mobile_NativeByedpiProxy_nativeStopProxy(
        JNIEnv *env, __attribute__((unused)) jclass clazz) {
    (void) env;
    pthread_mutex_lock(&proxy_mutex);
    int fd = server_fd;
    bool running = proxy_running;
    pthread_mutex_unlock(&proxy_mutex);
    if (!running || fd < 0) return -1;
    return shutdown(fd, SHUT_RDWR);
}

