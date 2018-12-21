#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

/* __MAX_OUTPUT is the maximum output length (no. of characters) allowed */
#define __SEPARATOR "\n#\n"

int redirected_printf(const char * format, ...) {
	// Make formatted string.
	char *new_format, *start_str, *stop_str, *len_mod, *sep_pos;
	int result;
	va_list ap;
	char mini_str[6];
	char interm_str[3];
#ifdef __MAX_OUTPUT
	static unsigned long output_len = 0;
#endif

	new_format = (char *)malloc((strlen(format)+1) * sizeof(char));
	if (new_format == NULL)
		return (-1);

	start_str = stop_str = (char *)format;
	*new_format = '\0';

	sep_pos = strstr(start_str, __SEPARATOR);

	while ((start_str = strchr(start_str, '%')) != NULL) {
		if (sep_pos != NULL && sep_pos <= start_str) {
			do {
				strcat(new_format, __SEPARATOR);
				sep_pos = strstr(sep_pos + strlen(__SEPARATOR), __SEPARATOR);
			} while (sep_pos && sep_pos <= start_str);
			sep_pos = NULL;
		}

		/* Scan for the next conversion specifier or for % */
		stop_str = strpbrk(start_str+1, "%diouxXeEfFgGaAcspnm");
		if (stop_str == NULL) { /* Format string error */
			free(new_format);
			return -1;
		}

		/* We wanted to just print a %. Strip it */
		if (*stop_str == '%') {
			start_str = stop_str+1;
			continue;
		}

		strcat(new_format, "%");

		/* Now check for length modifiers */
		memset(interm_str, 0, sizeof(interm_str));
		len_mod = strpbrk(start_str+1, "hlqLjzZt");
		if (len_mod != NULL && len_mod < stop_str) {
			interm_str[0] = *len_mod;
			/* Check for dual character length modifiers */
			if (interm_str[0] == 'h') {
				if (*(len_mod+1) == 'h') {
					interm_str[1] = 'h';
					interm_str[2] = '\0';
				}
			} else if (interm_str[0] == 'l') {
				if (*(len_mod+1) == 'l') {
					interm_str[1] = 'l';
					interm_str[2] = '\0';
				}
			} else
				interm_str[1] = '\0';
		}

		/* finalize this token by adding potential length modifiers,
		   the detected format specifier and a space */
		sprintf(mini_str, "%s%c ", interm_str, *stop_str);

		/* Add this token to the new format string */
		strcat(new_format, mini_str);

		/* Move on to look for the next token */
		start_str = stop_str+1;

		if (sep_pos == NULL)
			sep_pos = strstr(start_str, __SEPARATOR);
	}

	if (sep_pos != NULL) {
		strcat(new_format, __SEPARATOR);
		start_str = stop_str+1+strlen(__SEPARATOR);
		while ((start_str < format+strlen(format)) && ((sep_pos = strstr(start_str, __SEPARATOR))!= NULL)) {
			strcat(new_format, __SEPARATOR);
			start_str = start_str+strlen(__SEPARATOR);
		}
	}
	/* The stripped format string is ready. Use it to print */
	va_start(ap, format);
	result = vprintf(new_format, ap);

	free(new_format);

#ifdef __MAX_OUTPUT
	output_len += result;
	if (output_len > __MAX_OUTPUT) {
		vprintf("\nABORTED: OUTPUT TOO LONG\n", ap);
		exit(-1);
	}
#endif

	va_end(ap);
	return result;
}
