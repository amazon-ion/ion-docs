
import static org.junit.Assert.fail;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.MalformedInputException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.antlr.v4.runtime.ANTLRErrorListener;
import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.Recognizer;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;
import org.antlr.v4.runtime.tree.TerminalNode;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;

/**
 * Simple driver for recognizing and diagnosing Ion via the ANTLR defined grammar.
 */
@RunWith(Parameterized.class)
public final class GrammarTest {
    private static final String TEST_DATA_PATH_PROPERTY = "iontestdata.path";
    private static final File TEST_DATA_DIR;
    static {
        final String path = System.getProperty(TEST_DATA_PATH_PROPERTY);
        if (path == null) {
            throw new IllegalStateException(TEST_DATA_PATH_PROPERTY + " must be set");
        }
        TEST_DATA_DIR = new File(path);
        if (!TEST_DATA_DIR.isDirectory()) {
            throw new IllegalStateException(TEST_DATA_PATH_PROPERTY + " is not a directory: " + TEST_DATA_DIR);
        }
    }

    private static File testPath(final String name) {
        return new File(TEST_DATA_DIR, name);
    }

    private static final Set<File> SKIP_FILES;
    static {
        final Set<File> skip = new HashSet<>();

        // TODO add validation code for non-annotated top-level non 1.0 IVMs
        skip.add(testPath("bad/invalidVersionMarker_ion_0_0.ion"));
        skip.add(testPath("bad/invalidVersionMarker_ion_1234_0.ion"));
        skip.add(testPath("bad/invalidVersionMarker_ion_1_1.ion"));
        skip.add(testPath("bad/invalidVersionMarker_ion_2_0.ion"));
        // TODO add validation around Unicode escapes
        skip.add(testPath("bad/utf8/surrogate_5.ion"));

        // ANTLR test driver does not test UTF-16 or UTF-32
        skip.add(testPath("good/utf16.ion"));
        skip.add(testPath("good/utf32.ion"));

        SKIP_FILES = Collections.unmodifiableSet(skip);
    }

    public enum FileType {
        BAD,
        GOOD,
    }

    private static Object[] array(final Object... vals) {
        return vals;
    }

    private static void addTextFiles(final List<Object[]> params, final File directory, final FileType type) {
        final File[] entries = directory.listFiles();
        if (entries == null) {
            throw new IllegalStateException("Not a directory: " + directory);
        }
        for (final File entry : entries) {
            if (entry.isDirectory()) {
                addTextFiles(params, entry, type);
            } else if (entry.getName().endsWith(".ion") && !SKIP_FILES.contains(entry)) {
                params.add(array(entry, type));
            }
        }
    }

    @Parameters(name = "{1}: {0}")
    public static Collection<Object[]> parameters() {
        final List<Object[]> params = new ArrayList<>();
        addTextFiles(params, new File(TEST_DATA_DIR, "good"), FileType.GOOD);
        addTextFiles(params, new File(TEST_DATA_DIR, "bad"), FileType.BAD);
        return params;
    }

    @Parameter(0)
    public File file;

    @Parameter(1)
    public FileType type;

    private static final class AntlrError {
        public final int line;
        public final int pos;
        public final String msg;

        public AntlrError(final int line, final int pos, final String msg) {
            this.line = line;
            this.pos = pos;
            this.msg = msg;
        }

        @Override
        public String toString() {
            return "line " + line + ":" + pos + " - " + msg;
        }
    }

    private static final class AntlrErrorException extends RuntimeException {
        private static final long serialVersionUID = 1L;
        public final AntlrError error;

        public AntlrErrorException(AntlrError error) {
            this.error = error;
        }
    }

    private static final int[] MONTH_DAY_MAXIMUMS = {
        31, // JAN
        28, // FEB
        31, // MAR
        30, // APR
        31, // MAY
        30, // JUN
        31, // JUL
        31, // AUG
        30, // SEP
        31, // OCT
        30, // NOV
        31  // DEC
    };

    private static final int YEAR_POSITION                  = 0;
    private static final int MONTH_POSITION                 = 5;
    private static final int DAY_POSITION                   = 8;
    private static final int DAY_RESOLUTION_MIN_LENGTH      = 10;

    private static int parseIntField(final String text, final int position, final int length) {
        return Integer.parseInt(text.substring(position, position + length), 10);
    }

    private static boolean isLeapYear(final int year) {
        // from RFC-3339
        return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
    }

    /** Validates the day of month semantics for timestamp. */
    private static void validateTimestamp(final String text) {
        final int length = text.length();
        if (length >= DAY_RESOLUTION_MIN_LENGTH) {
            final int year  = parseIntField(text, YEAR_POSITION, 4);
            final int month = parseIntField(text, MONTH_POSITION, 2);
            final int day   = parseIntField(text, DAY_POSITION, 2);

            if (isLeapYear(year) && month == 2) {
                if (day > 29) {
                    throw new IllegalStateException("Invalid day number: " + text);
                }
            } else {
                if (day > MONTH_DAY_MAXIMUMS[month - 1]) {
                    throw new IllegalStateException("Invalid day number: " + text);
                }
            }
        }
    }

    /**
     * Performs additional validation on the grammar.
     * In particular, this does Timestamp verification.
     */
    private static final class IonTextValidatingListener extends IonTextBaseListener {
        @Override
        public void visitTerminal(final TerminalNode node) {
            final Token token = node.getSymbol();
            final String text = node.getText();
            try {
                switch (token.getType()) {
                case IonTextLexer.TIMESTAMP:
                    validateTimestamp(text);
                    break;
                default:
                    // ignore
                }
            } catch (final Exception e) {
                throw new AntlrErrorException(new AntlrError(token.getLine(), token.getStartIndex(), e.getMessage()));
            }
        }
    }

    @Test
    public void parse() throws Exception {
        final CharsetDecoder decoder = StandardCharsets.UTF_8.newDecoder();
        decoder.onMalformedInput(CodingErrorAction.REPORT);
        decoder.onUnmappableCharacter(CodingErrorAction.REPORT);
        try (final Reader in = new InputStreamReader(new FileInputStream(file), decoder)) {
            final List<AntlrError> errors = new ArrayList<>();
            try {
                final CharStream chars = new ANTLRInputStream(in);
                final IonTextLexer lexer = new IonTextLexer(chars);
                final TokenStream stream = new CommonTokenStream(lexer);
                final IonTextParser parser = new IonTextParser(stream);

                final ANTLRErrorListener listener = new BaseErrorListener() {
                    @Override
                    public void syntaxError(final Recognizer<?, ?> recognizer,
                                            final Object offendingSymbol,
                                            final int line,
                                            final int charPositionInLine,
                                            final String msg,
                                            final RecognitionException e) {
                        errors.add(new AntlrError(line, charPositionInLine, msg));
                    }
                };
                lexer.removeErrorListeners();
                parser.removeErrorListeners();
                lexer.addErrorListener(listener);
                parser.addErrorListener(listener);

                // parse!
                final ParseTree tree = parser.top_level();

                // intercept
                ParseTreeWalker walker = new ParseTreeWalker();
                walker.walk(new IonTextValidatingListener(), tree);
            } catch (final AntlrErrorException e) {
                errors.add(e.error);
            } catch (final MalformedInputException e) {
                errors.add(new AntlrError(-1, -1, e.getMessage()));
            }

            // check for errors
            switch (type) {
            case GOOD:
                if (!errors.isEmpty()) {
                    fail("Unexpected failure: " + errors);
                }
                break;
            case BAD:
                if (errors.isEmpty()) {
                    fail("Expected a error!");
                }
                break;
            default:
                throw new IllegalStateException("Unknown type: " + type);
            }
        }
    }
}
