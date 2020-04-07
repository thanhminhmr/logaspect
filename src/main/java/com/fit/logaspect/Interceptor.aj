package com.fit.logaspect;

import org.apache.log4j.Appender;
import org.apache.log4j.Logger;
import org.apache.log4j.WriterAppender;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.Signature;
import org.aspectj.lang.reflect.InitializerSignature;
import org.aspectj.lang.reflect.MethodSignature;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Enumeration;

public aspect Interceptor {
    static {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() {
                ArrayList<WriterAppender> writerAppenders = getAllWriterAppender(LOGGER);
                for (WriterAppender ap:writerAppenders)
                    ap.setImmediateFlush(true);
                // important
                LOGGER.info("Flush-end-of-log");
            }
        });
    }
    public static Logger LOGGER = Logger.getLogger(com.fit.logaspect.Interceptor.class.getName());
    pointcut setUpAll(): execution(@org.junit.BeforeClass * *(..)) || execution(@org.junit.jupiter.api.BeforeAll * *(..));
    pointcut setUpOnce(): execution(@org.junit.Before * *(..)) || execution(@org.junit.jupiter.api.BeforeEach * *(..));
    pointcut running(): execution(@org.junit.Test * *(..)) || execution(@org.junit.jupiter.api.Test * *(..));
    pointcut tearDownOnce(): execution(@org.junit.After * *(..)) || execution(@org.junit.jupiter.api.AfterEach * *(..));
    pointcut tearDownAll(): execution(@org.junit.AfterClass * *(..)) || execution(@org.junit.jupiter.api.AfterAll * *(..));
    pointcut traceMethods(): execution(* *(..)) && !cflow(within(com.fit.logaspect.Interceptor))
            && !within(org.junit.rules.TestRule+) && !within(org.junit.rules.MethodRule+)
            && !setUpOnce() && !setUpAll() && !running() && !tearDownOnce() && !tearDownAll()
            && !ruleSetup() && !ruleTearDown();

    // Look red? Don't worry, IntelliJ mess up hard here. AJC compile it just fine.
    pointcut ruleSetup(): execution(* org.junit.rules.ExternalResource+.before(..));
    pointcut ruleTearDown(): execution(* org.junit.rules.ExternalResource+.after(..));
    pointcut staticInit(): (staticinitialization(*Test) || staticinitialization(*..*Test) || staticinitialization(*..Test*) || staticinitialization(Test*)) && !within(com.fit.logaspect.Interceptor);


    before(): traceMethods() {
        logDebug(thisJoinPointStaticPart, LogPattern.METHOD_START);
    }
    after(): traceMethods(){
        logDebug(thisJoinPointStaticPart, LogPattern.METHOD_FINISH);
    }
    //	after() throwing (Throwable throwable): traceMethods(){
//		logExceptions(throwable, thisJoinPointStaticPart);
//	}

    before(): setUpAll(){
        logDebug(thisJoinPointStaticPart, LogPattern.SETUP_START_ALL);
    }
    after(): setUpAll(){
        logDebug(thisJoinPointStaticPart, LogPattern.SETUP_FINISH_ALL);
    }

    before(): setUpOnce(){
        logDebug(thisJoinPointStaticPart, LogPattern.SETUP_START_ONE);
    }
    after(): setUpOnce(){
        logDebug(thisJoinPointStaticPart, LogPattern.SETUP_FINISH_ONE);
    }

    before(): running(){
        logDebug(thisJoinPointStaticPart, LogPattern.TEST_METHOD_START);
    }
    after(): running(){
        logDebug(thisJoinPointStaticPart, LogPattern.TEST_METHOD_FINISH);
    }

    before(): tearDownOnce(){
        logDebug(thisJoinPointStaticPart, LogPattern.TEARDOWN_START_ONE);
    }
    after(): tearDownOnce(){
        logDebug(thisJoinPointStaticPart, LogPattern.TEARDOWN_FINISH_ONE);
    }

    before(): tearDownAll(){
        logDebug(thisJoinPointStaticPart, LogPattern.TEARDOWN_START_ALL);
    }
    after(): tearDownAll(){
        logDebug(thisJoinPointStaticPart, LogPattern.TEARDOWN_FINISH_ALL);
    }

    before(): ruleSetup(){
        logDebug(thisJoinPointStaticPart, LogPattern.RULE_SETUP_START);
    }
    after(): ruleSetup(){
        logDebug(thisJoinPointStaticPart, LogPattern.RULE_SETUP_FINISH);
    }

    before(): ruleTearDown(){
        logDebug(thisJoinPointStaticPart, LogPattern.RULE_TEARDOWN_START);
    }
    after(): ruleTearDown(){
        logDebug(thisJoinPointStaticPart, LogPattern.RULE_TEARDOWN_FINISH);
    }

    before(): staticInit(){
        logDebug(thisJoinPointStaticPart, LogPattern.STATIC_INIT_START);
    }
    after(): staticInit(){
        logDebug(thisJoinPointStaticPart, LogPattern.STATIC_INIT_FINISH);
    }

    private static ArrayList<WriterAppender> getAllWriterAppender(Logger logger){
        ArrayList<WriterAppender> was = new ArrayList<>();
        for (Enumeration aps = logger.getAllAppenders(); aps.hasMoreElements(); ) {
            Appender ap = (Appender) aps.nextElement();
            if (ap instanceof WriterAppender && !((WriterAppender)ap).getImmediateFlush()){
                was.add((WriterAppender)ap);
            }
        }
        return was;
    }
    public static void logDebug(JoinPoint.StaticPart staticPart, String message) {
        final Thread thread = Thread.currentThread();
        final Signature signature = staticPart.getSignature();
        Class clazz = signature.getDeclaringType();
        if (signature instanceof MethodSignature){
            MethodSignature methodSignature = (MethodSignature) signature;
            Method method = methodSignature.getMethod();
            ArrayList<String> ar = new ArrayList<>();
            for (Class cl : method.getParameterTypes()){
                ar.add(cl.getTypeName());
            }
            String params = String.join(LogPattern.PARAMS_DELIMITER,ar);
            LOGGER.log(org.apache.log4j.Level.toLevel(LogPattern.COMMAND_LOG_MODE),String.join(LogPattern.DELIMITER,
                    LogPattern.COMMAND_LOG_MODE, Long.toString(System.nanoTime()), Long.toString(thread.getId()),
                    message, method.getName(), params,clazz.getName(), clazz.getCanonicalName()));

        } else if (signature instanceof InitializerSignature){
//			InitializerSignature initializerSignature = (InitializerSignature) signature;
            LOGGER.log(org.apache.log4j.Level.toLevel(LogPattern.COMMAND_LOG_MODE),String.join(LogPattern.DELIMITER,
                    LogPattern.COMMAND_LOG_MODE, Long.toString(System.nanoTime()), Long.toString(thread.getId()),
                    message, "", "", clazz.getName(), clazz.getCanonicalName()));

        }
    }
}